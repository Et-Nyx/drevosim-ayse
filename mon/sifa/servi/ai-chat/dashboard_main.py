import os
import shutil
import time
import json
import collections
from fastapi import FastAPI, Request, File, UploadFile, HTTPException
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware

# Import the original FastAPI app instance
from api.src.main import app

# Ensure CORS is configured for API and dashboard access
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-memory stores for request history and active processes
MAX_LOGS = 100
api_calls = collections.deque(maxlen=MAX_LOGS)
active_processes = {}

# Startup: Synchronize read-only default voices to writeable VOICES_DIR
def initialize_voices():
    default_voices_dir = os.environ.get("DEFAULT_VOICES_DIR")
    voices_dir = os.environ.get("VOICES_DIR")
    
    if voices_dir and default_voices_dir and voices_dir != default_voices_dir:
        try:
            os.makedirs(voices_dir, exist_ok=True)
            # Check if there are any .pt voice files in the writeable dir
            try:
                has_pt_files = any(f.endswith('.pt') for f in os.listdir(voices_dir))
            except Exception:
                has_pt_files = False
                
            if not has_pt_files and os.path.exists(default_voices_dir):
                print(f"[Dashboard] Initializing writeable VOICES_DIR: {voices_dir}")
                print(f"[Dashboard] Copying default voices from: {default_voices_dir}")
                for item in os.listdir(default_voices_dir):
                    if item.endswith(".pt"):
                        src_item = os.path.join(default_voices_dir, item)
                        dst_item = os.path.join(voices_dir, item)
                        shutil.copy2(src_item, dst_item)
                print("[Dashboard] Voice profiles sync complete.")
        except Exception as e:
            print(f"[Dashboard] Warning: Failed to copy default voices to state directory: {str(e)}")

# Initialize voices on load
initialize_voices()

# Native ASGI Middleware to safely intercept and log requests without Starlette BaseHTTPMiddleware stream bugs
class DashboardASGIMiddleware:
    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        path = scope["path"]
        method = scope["method"]
        
        # Exclude dashboard status polling noise
        is_tracked_path = path.startswith("/v1/")
        if not is_tracked_path:
            await self.app(scope, receive, send)
            return

        # Extract User-Agent header safely
        headers_dict = dict(scope.get("headers", []))
        user_agent_bytes = headers_dict.get(b"user-agent", b"")
        user_agent = user_agent_bytes.decode("utf-8", "ignore")

        # Debug logging to journalctl
        print(f"[Dashboard Debug] {method} {path} - User-Agent: {user_agent}")

        request_id = f"req_{time.time_ns()}"
        start_time = time.time()
        
        # Capture body chunks passively as they are read by the endpoint
        body_chunks = []
        async def custom_receive():
            message = await receive()
            if message["type"] == "http.request":
                body_chunks.append(message.get("body", b""))
            return message

        status_code = [200]
        async def custom_send(message):
            if message["type"] == "http.response.start":
                status_code[0] = message["status"]
            await send(message)

        # Log entry placeholder
        client_ip = scope.get("client", ["Unknown"])[0] if scope.get("client") else "Unknown"
        log_entry = {
            "id": request_id,
            "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
            "client": f"{client_ip} (Intercepting...)",
            "method": method,
            "path": path,
            "payload": {},
            "status": "processing",
            "status_code": None,
            "duration": None,
            "error": None
        }
        
        # Add to global logs cache
        api_calls.appendleft(log_entry)
        active_processes[request_id] = log_entry

        # Execute application
        try:
            await self.app(scope, custom_receive, custom_send)
            
            # Request completed - now parse the captured body chunks
            full_body = b"".join(body_chunks)
            payload = {}
            if full_body:
                try:
                    data = json.loads(full_body)
                    if path == "/v1/audio/speech" and method == "POST":
                        raw_text = data.get("input", "")
                        text_preview = raw_text[:100] + "..." if len(raw_text) > 100 else raw_text
                        payload = {
                            "text": text_preview,
                            "text_length": len(raw_text),
                            "voice": data.get("voice", ""),
                            "speed": data.get("speed", 1.0),
                            "response_format": data.get("response_format", "mp3")
                        }
                    elif path == "/v1/audio/voices/combine" and method == "POST":
                        payload = {
                            "base_voice": data.get("base_voice", ""),
                            "blend_voice": data.get("blend_voice", ""),
                            "blend_ratio": data.get("blend_ratio", 0.5),
                            "output_voice_name": data.get("output_voice_name", "")
                        }
                except Exception as e:
                    payload = {"error": f"Failed to parse payload: {str(e)}"}

            # Identify source
            source = "Unknown"
            ua_lower = user_agent.lower()
            if "sillytavern" in ua_lower:
                source = "SillyTavern"
            elif "mozilla" in ua_lower or "chrome" in ua_lower or "safari" in ua_lower:
                source = "Dashboard/Browser"
            elif "python" in ua_lower or "requests" in ua_lower:
                source = "Python Script"
            elif "curl" in ua_lower:
                source = "curl"
            else:
                source = user_agent.split('/')[0] if '/' in user_agent else user_agent
                if len(source) > 20:
                    source = source[:20]

            log_entry["client"] = f"{client_ip} ({source})"
            log_entry["payload"] = payload
            log_entry["status_code"] = status_code[0]
            log_entry["status"] = "completed" if status_code[0] < 400 else "failed"
            log_entry["duration"] = round(time.time() - start_time, 2)
        except Exception as e:
            # Request crashed
            duration = round(time.time() - start_time, 2)
            log_entry["duration"] = duration
            log_entry["status"] = "failed"
            log_entry["status_code"] = 500
            log_entry["error"] = str(e)
            raise e
        finally:
            active_processes.pop(request_id, None)

# Add native ASGI middleware to application
app.add_middleware(DashboardASGIMiddleware)


# --- DASHBOARD API ENDPOINTS ---

@app.get("/dashboard", response_class=HTMLResponse)
async def get_dashboard():
    try:
        dir_path = os.path.dirname(os.path.realpath(__file__))
        html_path = os.path.join(dir_path, "dashboard.html")
        with open(html_path, "r", encoding="utf-8") as f:
            html_content = f.read()
        return HTMLResponse(content=html_content)
    except Exception as e:
        return HTMLResponse(
            content=f"<h1>Error loading dashboard template</h1><p>{str(e)}</p>", 
            status_code=500
        )

@app.get("/dashboard/api/status")
async def get_status():
    cpu_pct = 0.0
    mem_pct = 0.0
    mem_used = 0.0
    mem_total = 0.0
    
    # Fetch CPU/Memory metrics using psutil (which we ensure is packaged)
    try:
        import psutil
        cpu_pct = psutil.cpu_percent()
        mem = psutil.virtual_memory()
        mem_pct = mem.percent
        mem_used = round(mem.used / (1024**3), 2)
        mem_total = round(mem.total / (1024**3), 2)
    except Exception:
        pass
        
    # Fetch GPU metrics using GPUtil if available
    gpu_info = []
    try:
        import GPUtil
        gpus = GPUtil.getGPUs()
        for g in gpus:
            gpu_info.append({
                "id": g.id,
                "name": g.name,
                "load": round(g.load * 100, 1),
                "memory_used": g.memoryUsed,
                "memory_total": g.memoryTotal,
                "temperature": g.temperature
            })
    except Exception:
        pass
        
    return {
        "cpu_percent": cpu_pct,
        "memory_percent": mem_pct,
        "memory_used_gb": mem_used,
        "memory_total_gb": mem_total,
        "gpu": gpu_info,
        "active_processes_count": len(active_processes),
        "active_processes": list(active_processes.values())
    }

@app.get("/dashboard/api/calls")
async def get_calls():
    return list(api_calls)

@app.post("/dashboard/api/voices/upload")
async def upload_voice(file: UploadFile = File(...)):
    voices_dir = os.environ.get("VOICES_DIR")
    if not voices_dir:
        raise HTTPException(status_code=400, detail="VOICES_DIR environment variable is not configured")
        
    if not file.filename.endswith(".pt"):
        raise HTTPException(status_code=400, detail="Only .pt voice file format is supported")
        
    try:
        os.makedirs(voices_dir, exist_ok=True)
        dest_path = os.path.join(voices_dir, file.filename)
        with open(dest_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        return {"status": "success", "filename": file.filename}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to save voice file: {str(e)}")

@app.delete("/dashboard/api/voices/{filename}")
async def delete_voice(filename: str):
    voices_dir = os.environ.get("VOICES_DIR")
    if not voices_dir:
        raise HTTPException(status_code=400, detail="VOICES_DIR environment variable is not configured")
        
    # Sanitize filename
    safe_filename = os.path.basename(filename)
    if not safe_filename.endswith(".pt"):
        raise HTTPException(status_code=400, detail="Invalid voice file name format")
        
    file_path = os.path.join(voices_dir, safe_filename)
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="Voice file not found in VOICES_DIR")
        
    try:
        os.remove(file_path)
        return {"status": "success", "message": f"Deleted voice profile {safe_filename}"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete voice: {str(e)}")

# --- COMPATIBILITY FALLBACKS FOR SILLYTAVERN ---
# SillyTavern's OpenAI Compatible TTS provider sends requests directly to the base URL (/v1 or /v1/)
# instead of appending /audio/speech. We redirect these requests with HTTP 307 (preserving method & payload).
from fastapi.responses import RedirectResponse

@app.post("/v1")
async def openai_v1_post_fallback(request: Request):
    return RedirectResponse(url="/v1/audio/speech", status_code=307)

@app.post("/v1/")
async def openai_v1_slash_post_fallback(request: Request):
    return RedirectResponse(url="/v1/audio/speech", status_code=307)

@app.get("/v1")
async def openai_v1_get_fallback(request: Request):
    return RedirectResponse(url="/v1/audio/voices", status_code=307)

@app.get("/v1/")
async def openai_v1_slash_get_fallback(request: Request):
    return RedirectResponse(url="/v1/audio/voices", status_code=307)
