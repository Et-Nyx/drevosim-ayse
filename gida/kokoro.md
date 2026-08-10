# Kokoro TTS — Operator's Manual

A practical guide to the [Kokoro-FastAPI](https://github.com/remsky/Kokoro-FastAPI)
server running on `ayse`. Read this when you need to generate speech from
text, debug a TTS request, or manage custom voice packs.

The service exposes an OpenAI-compatible text-to-speech API at
`http://<ayse-ip>:8880/v1` and a web dashboard at
`http://<ayse-ip>:8880/dashboard`.

---

## Table of contents

- [What it is](#what-it-is)
- [How it works](#how-it-works)
- [Configuration options](#configuration-options)
- [Quick start](#quick-start)
- [API reference](#api-reference)
- [The 67 voices](#the-67-voices)
- [The web dashboard](#the-web-dashboard)
- [Client configuration](#client-configuration)
- [State and persistence](#state-and-persistence)
- [GPU mode](#gpu-mode)
- [Troubleshooting](#troubleshooting)
- [Service management](#service-management)
- [Uninstall / disable](#uninstall--disable)

---

## What it is

- A self-contained, **offline** [Kokoro-FastAPI](https://github.com/remsky/Kokoro-FastAPI)
  v0.5.0 server. Nothing is downloaded at runtime.
- The Kokoro-82M v1.0 model, all 67 voice packs, and the English G2P
  spaCy model are all bundled into the Nix store at build time.
- Exposes an OpenAI-compatible TTS API at `/v1/audio/speech` plus a
  `/v1/audio/voices` listing.
- Bundles a **web dashboard** at `/dashboard` with a speech playground,
  voice manager, live system metrics, and an API call inspector.
- English and Portuguese voices are first-class; many other languages
  are available (see [The 67 voices](#the-67-voices)).

---

## How it works

```
┌──────────────┐   HTTP/8880  ┌────────────────────┐
│   Client     │<────────────>│ uvicorn            │
│ (SillyTavern,│  /v1/*       │ (kokoro-tts)       │
│  curl,       │  /dashboard  │   ├─ worker 0      │
│  browser)    │              │   │  ├─ dashboard  │
└──────────────┘              │   │  │  middleware │
                               │   │  │  (logging,  │
                               │   │  │   voices,   │
                               │   │  │   redirect) │
                               │   │  └─ FastAPI    │
                               │   │     app        │
                               │   └─ worker 1      │
                               │      (same shape)  │
                               └───────┬────────────┘
                                       │
                                       ▼
                       Kokoro-82M v1.0 (~327 MB)
                       67 voice packs (.pt files)
                       en_core_web_sm (spaCy)
                       misaki (G2P)
```

The uvicorn process is launched with `--workers 2` (see
`mon/sifa/servi/ai-chat/kokoro.nix:246`). Each worker is an
independent process with its own copy of the 82M model in RAM
(~1.1 GB each, so the service uses ~2.2 GB at idle). Requests are
dispatched to whichever worker is free, so a long `/v1/audio/speech`
inference on one worker does not block `/health`, `/v1/audio/voices`,
or dashboard polling on the other.

- **uvicorn** runs the FastAPI app `api.src.dashboard_main:app` (see
  `mon/sifa/servi/ai-chat/dashboard_main.py`). The wrapper sits in
  front of the upstream app and:
  - copies the bundled voices into the writable `VOICES_DIR` on first
    run,
  - records the last 100 `/v1/*` requests (caller, payload, status,
    duration) for the dashboard,
  - exposes 307 redirects for `/v1` and `/v1/` so clients that forget
    the `/audio/speech` suffix still work.
- The service runs as the static `kokoro-tts` user (not `DynamicUser`,
  because `StateDirectory` collides with the preservation bind-mount).
- At boot the service loads the model into RAM (~1–1.5 GB), runs a
  warmup utterance with `af_heart`, and then serves requests.
- **No generated audio is stored on disk.** Every request tokenizes
  the text, loads the requested voice, runs inference, and streams
  the audio back to the client.

---

## Configuration options

All options live under `drevosim.servi.kokoro.*`. Defaults:

| Option | Default | Description |
|--------|---------|-------------|
| `enable` | `false` | Master switch. Set to `true` in `estandar.nix` to enable. |
| `gpu` | `false` | Use CUDA on the Pascal MX150 instead of CPU. |
| `host` | `0.0.0.0` | Bind address. |
| `port` | `8880` | Bind port. |
| `openFirewall` | `true` | Open the port in the firewall. |
| `stateDir` | `/var/lib/kokoro-tts` | (read-only) Runtime working directory. |

To change, edit `mon/mehmangi/ayse/estandar.nix`:

```nix
drevosim.servi.kokoro = {
  enable = true;
  gpu = false;     # flip to true once you've verified CPU works
  port = 8880;
};
```

Then `sudo nixos-rebuild switch --flake .`.

---

## Quick start

1. Confirm the service is running:

   ```bash
   systemctl status kokoro-tts
   ```

   You should see `Active: active (running)`. The first start can take
   20–40 seconds while the model loads.

2. Confirm the port is listening:

   ```bash
   sudo ss -tlnp | grep 8880
   ```

3. Hit the health endpoint:

   ```bash
   curl http://127.0.0.1:8880/health
   ```

4. List the voices:

   ```bash
   curl http://127.0.0.1:8880/v1/audio/voices | jq
   ```

5. Generate a test utterance:

   ```bash
   curl http://127.0.0.1:8880/v1/audio/speech \
     -H 'Content-Type: application/json' \
     -d '{"model":"kokoro","input":"Hello from Kokoro.","voice":"af_heart","response_format":"mp3"}' \
     -o hello.mp3
   ```

6. Open the dashboard:

   ```
   http://<ayse-ip>:8880/dashboard
   ```

---

## API reference

All endpoints are under `/v1` to be OpenAI-compatible.

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/v1/models` | GET | Returns the model list. Currently a single entry: `kokoro`. |
| `/v1/audio/voices` | GET | Returns the 67 available voice IDs. |
| `/v1/audio/speech` | POST | Generate audio from text. |
| `/health` | GET | Health check. |
| `/dashboard` | GET | Web dashboard. |

### `POST /v1/audio/speech`

Request body:

```json
{
  "model": "kokoro",
  "input": "Hello, world.",
  "voice": "af_heart",
  "response_format": "mp3",
  "speed": 1.0
}
```

- `model` — must be `"kokoro"`.
- `input` — the text to speak.
- `voice` — one of the 67 IDs from `/v1/audio/voices` (see below).
- `response_format` — one of `mp3`, `wav`, `opus`, `aac`, `flac`.
- `speed` — optional, defaults to `1.0`. Range typically `0.5`–`2.0`.

Response: the audio bytes, with `Content-Type` matching
`response_format`.

### Examples

```bash
# English
curl http://127.0.0.1:8880/v1/audio/speech \
  -H 'Content-Type: application/json' \
  -d '{"model":"kokoro","input":"Hello from Kokoro.","voice":"af_heart","response_format":"mp3"}' \
  -o hello.mp3

# Portuguese
curl http://127.0.0.1:8880/v1/audio/speech \
  -H 'Content-Type: application/json' \
  -d '{"model":"kokoro","input":"Olá, isto é um teste.","voice":"pf_dora","response_format":"mp3"}' \
  -o ola.mp3

# Opus for low-bandwidth
curl http://127.0.0.1:8880/v1/audio/speech \
  -H 'Content-Type: application/json' \
  -d '{"model":"kokoro","input":"Compact.","voice":"am_echo","response_format":"opus"}' \
  -o compact.opus

# Slow
curl http://127.0.0.1:8880/v1/audio/speech \
  -H 'Content-Type: application/json' \
  -d '{"model":"kokoro","input":"Slow and clear.","voice":"af_heart","response_format":"mp3","speed":0.75}' \
  -o slow.mp3
```

---

## The 67 voices

Voice IDs use a two-letter prefix that indicates language/accent and
gender:

| Prefix | Language / accent | Gender | Count |
|--------|-------------------|--------|-------|
| `af_` | American English | Female | 18 |
| `am_` | American English | Male | 12 |
| `bf_` | British English | Female | 5 |
| `bm_` | British English | Male | 6 |
| `ef_` | Spanish | Female | 1 |
| `em_` | Spanish | Male | 2 |
| `ff_` | French | Female | 1 |
| `hf_` | Hindi | Female | 2 |
| `hm_` | Hindi | Male | 2 |
| `if_` | Italian | Female | 1 |
| `im_` | Italian | Male | 1 |
| `jf_` | Japanese | Female | 4 |
| `jm_` | Japanese | Male | 1 |
| `pf_` | Portuguese | Female | 1 |
| `pm_` | Portuguese | Male | 2 |
| `zf_` | Chinese | Female | 4 |
| `zm_` | Chinese | Male | 4 |

Notable voices:

- **English defaults**: `af_heart`, `af_bella`, `af_nova`, `am_adam`, `am_echo`
- **Portuguese**: `pf_dora`, `pm_alex`, `pm_santa`
- **Japanese**: `jf_alpha`, `jm_kumo`
- **Spanish**: `ef_dora`, `em_alex`
- **French**: `ff_siwis`

Full voice list:

```text
af_alloy, af_aoede, af_bella, af_heart, af_jadzia, af_jessica, af_kore,
af_nicole, af_nova, af_river, af_sarah, af_sky, af_v0, af_v0bella,
af_v0irulan, af_v0nicole, af_v0sarah, af_v0sky, am_adam, am_echo,
am_eric, am_fenrir, am_liam, am_michael, am_onyx, am_puck, am_santa,
am_v0adam, am_v0gurney, am_v0michael, bf_alice, bf_emma, bf_lily,
bf_v0emma, bf_v0isabella, bm_daniel, bm_fable, bm_george, bm_lewis,
bm_v0george, bm_v0lewis, ef_dora, em_alex, em_santa, ff_siwis,
hf_alpha, hf_beta, hm_omega, hm_psi, if_sara, im_nicola, jf_alpha,
jf_gongitsune, jf_nezumi, jf_tebukuro, jm_kumo, pf_dora, pm_alex,
pm_santa, zf_xiaobei, zf_xiaoni, zf_xiaoxiao, zf_xiaoyi, zm_yunjian,
zm_yunxi, zm_yunxia, zm_yunyang
```

### Quick preview loop

```bash
for v in af_heart af_bella af_nova am_adam am_echo pf_dora pm_alex; do
  curl -s http://127.0.0.1:8880/v1/audio/speech \
    -H 'Content-Type: application/json' \
    -d "{\"model\":\"kokoro\",\"input\":\"This is ${v}.\",\"voice\":\"${v}\",\"response_format\":\"mp3\"}" \
    -o /tmp/${v}.mp3
done
```

---

## The web dashboard

Open `http://<ayse-ip>:8880/dashboard` in any browser. It provides:

### Speech playground
Type text, pick a voice and format, click **Generate**. The audio
plays inline and can be copied to the clipboard or downloaded.

### Voice manager
- Lists all 67 bundled voices plus any custom voices uploaded at
  runtime.
- **Upload** a new `.pt` voice pack (drag-and-drop or file picker).
  The file is written to `${stateDir}/voices` (preserved on
  `/persistent`), so it survives reboots.
- **Delete** custom voices. Bundled voices cannot be deleted from the
  UI (they live in the Nix store and are read-only).

### System status
Live CPU, RAM, and (when GPU mode is on) VRAM metrics, plus a count
of in-flight `/v1/*` requests.

### API call log
The last 100 `/v1/*` requests, each with:
- Caller identification (SillyTavern, browser, curl, Python,
  unknown) derived from the `User-Agent` header.
- Payload preview (truncated).
- Status code and duration.

The log is held in process memory — restarting the service clears it.

---

## Client configuration

### SillyTavern (already pre-configured by the sister module)

- **Extensions → TTS → OpenAI Compatible**
- URL: `http://127.0.0.1:8880/v1`
- Voice: `af_heart`
- API key: anything (ignored)

See `gida/sillytavern.md` for the full SillyTavern setup.

### Open WebUI

- TTS engine: **OpenAI-compatible**
- URL: `http://<ayse-ip>:8880/v1`
- API key: any dummy value
- Pick a voice from the list.

### Any OpenAI TTS client

Point it at `http://<ayse-ip>:8880/v1` and use a voice ID from
`/v1/audio/voices`.

### `mpv` from the command line

```bash
curl -s http://127.0.0.1:8880/v1/audio/speech \
  -H 'Content-Type: application/json' \
  -d '{"model":"kokoro","input":"Streamed directly to mpv.","voice":"af_heart","response_format":"mp3"}' \
  | mpv --no-cache --no-terminal -
```

---

## State and persistence

`/var/lib/kokoro-tts` is preserved on `/persistent` so the runtime
state survives reboots. The directory contains:

- `voices/` — custom voice packs uploaded through the dashboard.
  Empty by default; you upload `.pt` files as needed.

The model and voice packs themselves live in the Nix store
(`/nix/store/...-kokoro-fastapi-0.5.0/...`) and are read-only. The
service does not write generated audio to disk — every request is
streamed to the client and discarded.

---

## GPU mode

Kokoro can use the Pascal MX150's CUDA cores for inference. To enable:

```nix
drevosim.servi.kokoro = {
  enable = true;
  gpu = true;
};
```

Then `sudo nixos-rebuild switch --flake .`.

### What GPU mode does

- Switches `USE_GPU=true` and `DEVICE_TYPE=cuda` in the service
  environment.
- Builds a CUDA-enabled `torch` derivation at build time. The
  global `nixpkgs.config.cudaCapabilities = [ "6.1" ]` (set in
  `gida/nvidia.md`) makes PyTorch target the Pascal MX150's compute
  capability.

### What GPU mode costs

- A **long build**. CUDA PyTorch for `6.1` is not in the binary
  cache; it gets built from source. The first `nixos-rebuild switch`
  after enabling `gpu = true` can take 30+ minutes and gigabytes of
  disk space.
- A **heavy runtime**. CUDA PyTorch eagerly loads CUDA libraries and
  initializes the GPU on first use. The model still runs in CPU
  memory; only the inference kernels run on the GPU.

### When to enable

If you're generating more than a few minutes of audio per hour, GPU
mode is noticeably faster. For occasional use, CPU mode is fine and
keeps the system simple.

### Verify GPU is being used

```bash
journalctl -u kokoro-tts | grep -i device
```

Should show `cuda`. Or check the dashboard's "System status" panel —
it reports VRAM usage when the GPU is active.

---

## Troubleshooting

### Service won't start: "address already in use"

Another process is bound to port 8880. Find it:

```bash
sudo ss -tlnp | grep 8880
```

Either kill it or change `drevosim.servi.kokoro.port`.

### Service starts but `/health` hangs

The model is still loading. First start takes 20–40 seconds. Watch:

```bash
journalctl -u kokoro-tts -f
```

If `/health` times out *after* startup, another `/v1/audio/speech`
request is holding a worker. The unit runs two uvicorn workers, so
the other worker should pick the probe up within a few seconds. If
both workers are saturated, the request is simply queued — the
service is not stuck.

### `/v1/audio/speech` is slow

Expected on CPU. Each ~200-token chunk takes roughly 20–40 s on the
Pascal MX150's i7; a long paragraph of 16 chunks can take 5–10
minutes end-to-end. The client should stream the response, not wait
for the whole body. If you need faster turnaround, enable GPU mode
(`drevosim.servi.kokoro.gpu = true`) — see [GPU mode](#gpu-mode).

### 500 errors on `/v1/audio/speech`

Check the journal for the actual stack trace. Common causes:

- The requested voice is not in the bundle. Confirm with
  `curl http://127.0.0.1:8880/v1/audio/voices | jq`.
- The English G2P model failed to load. This should be impossible
  because it's bundled, but if you see `en_core_web_sm not found`,
  the build is broken — file an issue.

### Audio is silent or has wrong content

You're probably sending the request to the wrong model name. Only
`"kokoro"` is supported.

### Dashboard says "API call log: 0 requests" but I just made one

The log is in-memory. Restarting the service clears it. Also, only
`/v1/*` requests are logged; `/health` and `/dashboard` are not.

### GPU mode: torch CUDA error

Run:

```bash
journalctl -u kokoro-tts | grep -iE 'cuda|nvml|nvidia'
```

If you see `libcuda.so not found` or similar, the nvidia kernel
module isn't loaded. See `gida/nvidia.md` for the full NVIDIA setup.

---

## Service management

The service is `kokoro-tts.service`, a normal systemd unit.

```bash
# Status
systemctl status kokoro-tts

# Start / stop / restart
sudo systemctl start kokoro-tts
sudo systemctl stop kokoro-tts
sudo systemctl restart kokoro-tts

# Live logs
journalctl -u kokoro-tts -f

# Last 50 log lines
journalctl -u kokoro-tts -n 50 --no-pager
```

### Hardening

The unit runs with:

- `Type = exec` — no forking by the unit. Uvicorn itself forks
  the two workers from its parent process; the parent stays as the
  systemd-tracked PID and reaps workers on stop.
- `--workers 2` on the `uvicorn` command line — two independent
  worker processes, each with its own copy of the 82M model in RAM
  (~1.1 GB per worker, ~2.2 GB total at idle). Requests are
  dispatched round-robin, so a long inference on one worker does
  not block `/health`, `/v1/audio/voices`, or the dashboard.
- `User = kokoro-tts` — dedicated static user (not `DynamicUser`,
  because `StateDirectory` collides with the preservation bind-mount).
- `Group = kokoro-tts`, plus `video` when GPU mode is on.
- `StateDirectory = kokoro-tts` — the writable working directory.
- `WorkingDirectory = /var/lib/kokoro-tts`.
- `ProtectSystem = strict` — the entire filesystem is read-only
  except for the paths in `ReadWritePaths`.
- `ProtectHome = true` — `/home` and `/root` are inaccessible.
- `PrivateTmp = true` — the service gets its own `/tmp`.
- `NoNewPrivileges = true`.

---

## Uninstall / disable

```nix
# In mon/mehmangi/ayse/estandar.nix
drevosim.servi.kokoro.enable = false;
```

Then `sudo nixos-rebuild switch --flake .`. The service will be
stopped and removed; the package will no longer be in the system
closure. The `/var/lib/kokoro-tts` directory is left in place
(preserved on `/persistent`) and can be deleted manually if you want
to reclaim space.

---

## Quick reference

```bash
# Status
systemctl status kokoro-tts

# Health
curl http://127.0.0.1:8880/health

# Voices
curl http://127.0.0.1:8880/v1/audio/voices | jq

# Speak
curl http://127.0.0.1:8880/v1/audio/speech \
  -H 'Content-Type: application/json' \
  -d '{"model":"kokoro","input":"Hello.","voice":"af_heart","response_format":"mp3"}' \
  -o hello.mp3

# Dashboard
echo "http://$(hostname -I | awk '{print $1}'):8880/dashboard"
```

If something doesn't work, check `journalctl -u kokoro-tts -n 50`
first.
