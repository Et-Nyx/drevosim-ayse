# NixOS — Impermanent Setup

This repository contains the declarative NixOS configuration for a single machine (`ayse`) running an **impermanent** (ephemeral root) setup with [Disko](https://github.com/nix-community/disko) and [preservation](https://github.com/nix-community/preservation).

The flake is organized in a dendritic (tree-like) structure inspired by [Drevosim](flakes/drevosim-ayse/README.md): a single flake root feeds a trunk of module directories, which split into hosts, features, helpers, and secrets.

## Overview

- **Root filesystem (`/`)**: `tmpfs` created fresh on every boot.
- **`/home`**: `tmpfs`, recreated fresh on every boot.
- **`/nix`**: Dedicated Btrfs subvolume on the SSD, persisted across reboots.
- **`/persistent`**: Btrfs partition on the HDD for all system and user state preserved by `preservation`.
- **Desktop**: KDE Plasma 6 with SDDM.

## File Layout

```text
.
├── flake.nix              # flake-parts + import-tree entry point
├── flake.lock             # locked input revisions
├── README.md              # this file
├── mon/                   # module tree (imported recursively by import-tree)
│   ├── parts.nix          # flake-parts systems configuration
│   ├── basi.nix           # shared base options (userName, nix settings, GC, unfree)
│   ├── mehmangi/          # machines / hosts
│   │   └── ayse/          # host configuration for machine `ayse`
│   │       ├── estandar.nix    # host assembler (defines `.#ayse`)
│   │       ├── ogarli.nix      # user configuration
│   │       ├── loka.nix        # locale, timezone, keymaps
│   │       └── nukleus/        # core host configuration
│   │           ├── estrutur.nix   # hostname & host-specific structure
│   │           ├── hardwer.nix    # hardware/kernel configuration
│   │           ├── xoru.nix       # bootloader configuration
│   │           ├── disko.nix      # disk partitioning & filesystem layout
│   │           ├── nvidia.nix     # NVIDIA PRIME offload & iGPU specialisation
│   │           ├── preservation.nix # preservation rules for the ephemeral root
│   │           └── siri.nix       # agenix secret declarations
│   └── sifa/              # feature modules
│       ├── kolor/         # theming & customization
│       │   └── tul.nix
│       ├── kuflu/         # security & login (ly, sddm)
│       │   ├── ly.nix
│       │   ├── sddm.nix
│       │   ├── tul.nix
│       │   └── faylu/     # raw config files (filtered from import-tree)
│       │       ├── ly.ini
│       │       └── sddm.conf
│       ├── medya/         # audio / video
│       │   ├── bluetooth.nix
│       │   ├── pipewire.nix
│       │   └── tul.nix
│       ├── mesa/          # window managers, compositors & desktops
│       │   ├── plasma.nix
│       │   ├── tul.nix
│       │   └── river/
│       │       ├── river.nix
│       │       ├── canoe.nix
│       │       ├── rill.nix
│       │       └── faylu/ # raw config files (filtered from import-tree)
│       │           ├── canoe.toml
│       │           └── rill.zon
│       ├── produti/       # productivity tools
│       │   └── tul.nix
│       ├── programa/      # general programs
│       │   ├── fuzzel.nix
│       │   ├── tul.nix
│       │   └── faylu/     # raw config files (filtered from import-tree)
│       │       └── fuzzel.ini
│       ├── servi/         # system services
│       │   ├── network.nix
│       │   ├── openssh.nix
│       │   ├── mako.nix
│       │   ├── polkit.nix
│       │   ├── tul.nix
        │   │   ├── ai-chat/   # AI chat services
        │   │   │   ├── kokoro.nix        # Kokoro TTS API server + dashboard
        │   │   │   ├── sillytavern.nix   # SillyTavern web UI + extensions
        │   │   │   ├── dashboard.html    # Kokoro web dashboard UI
        │   │   │   └── dashboard_main.py # Kokoro dashboard middleware
        │   │   ├── ftp.nix            # anonymous FTP server (vsftpd)
        │   │   └── faylu/     # raw config files (filtered from import-tree)
│       │       └── mako.ini
│       ├── terminal/      # terminal emulators, shells & CLI tools
│       │   ├── foot.nix
│       │   ├── fish.nix
│       │   ├── nushell.nix
│       │   ├── tul.nix
│       │   └── faylu/     # raw config files (filtered from import-tree)
│       │       ├── config.fish
│       │       ├── config.nu
│       │       └── foot.ini
│       └── yuxi/          # gaming
│           ├── steam.nix
│           ├── heroic.nix
│           └── tul.nix
├── offolo/                # offline / external build dependencies
│   └── rill.nix           # vendored Zig dependencies for rill
├── siri/                  # encrypted secrets for agenix
│   ├── secrets.nix        # recipient public keys
│   ├── ayse-root-pasalexi.age
│   ├── ayse-eter-pasalexi.age
│   └── ayse-go-relay.age  # OpenCode Go relay access token
└── yongu/                 # helper functions
    ├── monlari.nix        # recursive NixOS-module collector
    └── parseIni.nix       # pure-Nix INI parser for faylu/ files
```

## Disks

Configured in `mon/mehmangi/ayse/nukleus/disko.nix`:

- `/dev/nvme0n1` — SSD (boot, swap, `/nix`)
  - `ESP` (1 GiB, vfat, `/boot`)
  - `swap` (16 GiB)
  - `root` (remainder, Btrfs)
    - subvolume `nix` → `/nix`
- `/dev/sda` — HDD (`/persistent`)
  - single Btrfs partition with zstd compression
  - holds all preserved state: SSH keys, NetworkManager data, browser profiles, KDE config, and the flake checkout

> **Warning:** The Disko configuration references specific device names. Always double-check these paths on the target hardware before running any destructive Disko command.

## Rebuilding the System

From this directory:

```bash
sudo nixos-rebuild switch --flake .
```

Or explicitly:

```bash
sudo nixos-rebuild switch --flake .#ayse
```

## Updating

Update flake inputs and rebuild:

```bash
nix flake update
sudo nixos-rebuild switch --flake .
```

## Reinstalling from Scratch

1. Boot a recent NixOS installer USB.
2. Connect to the network and clone this repo.
3. Verify/adjust disk device names in `mon/mehmangi/ayse/nukleus/disko.nix`.
4. Run Disko to partition and format:

   ```bash
   sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode destroy,format,mount ./mon/mehmangi/ayse/nukleus/disko.nix
   ```

5. Install NixOS:

   ```bash
   sudo nixos-install --flake .#ayse
   ```

6. Reboot, set the user password, and continue using `nixos-rebuild switch` as normal.

## Notable Configuration Details

- `/etc/nixos` is symlinked to `/persistent/nixos` via `systemd.tmpfiles.rules` so the canonical config survives on the persistent volume.
- Flakes and `nix-command` are enabled.
- Automatic GC keeps generations newer than 7 days.
- SSH is enabled with password authentication (intended to be switched to key-only once keys are deployed).
- Locale is `pt_BR.UTF-8` and timezone is `America/Recife`.
- User and root passwords are stored as age-encrypted hashes in `siri/` and decrypted at boot by `agenix`.
- `users.mutableUsers = false` so `/etc/shadow` always matches the NixOS configuration.
- Stale Chromium lock files and KWallet data are cleaned on every boot.
- Preserved home directories include `~/.config` (KDE Plasma + Chromium config), `~/.local/share` and `~/.local/state` (application data), `~/.ssh`, and the standard XDG user folders including `~/Games` (used by Heroic and Steam for large game installs that would otherwise fill the tmpfs root).
- Preserved system state includes `/etc/ssh`, `/var/lib/bluetooth` (pairing keys), `/var/lib/NetworkManager/system-connections`, `/var/lib/nixos` (user/group database), `/var/lib/kokoro-tts` (TTS service state, including custom `.pt` voice packs uploaded through the dashboard), `/var/lib/SillyTavern` (SillyTavern data), and `/var/lib/ftp-srv` (anonymous FTP root, including the writable `upload/` subdirectory).
- Bluetooth is enabled (`hardware.bluetooth`) with `powerOnBoot = true` and `bluez` in `systemPackages`.

### NVIDIA (Optimus / PRIME)

Configured in `mon/mehmangi/ayse/nukleus/nvidia.nix`. The host (`ayse`) is a Dell Inspiron 7580 with Intel UHD 630 (iGPU) and NVIDIA GeForce MX150 (GP108M, Pascal). The dGPU is wired to a 3D controller class (no display), so PRIME render-offload is the only way to use it.

- `hardware.nvidia.package` is pinned to `legacy_580` (Pascal support was dropped in the 595+ production branch).
- `hardware.nvidia.open = false` (Pascal is not supported by the open kernel modules).
- `prime.offload.enable = true` with `prime-run` exposed at `/run/current-system/sw/bin`.
- `prime.reverseSync.enable = true` to render dGPU output on the iGPU's display.
- Global `__NV_PRIME_RENDER_OFFLOAD` / `__GLX_VENDOR_LIBRARY_NAME` / `__VK_LAYER_NV_optimus` env vars are set in `environment.sessionVariables` so user-launched apps prefer the dGPU.
- `cudaCapabilities = [ "6.1" ]` (Pascal compute capability).
- `boot.kernelParams = [ "pcie_aspm=off" "nvidia-drm.modeset=1" ]` and a udev rule force the dGPU out of D3cold at boot. Without this, the firmware-parked dGPU is undetectable.

An `igpu` specialisation is defined for fallback: it blacklists all nvidia kernel modules, forces `services.xserver.videoDrivers = [ "modesetting" ]`, and unsets the PRIME env vars. Boot it from the systemd-boot menu if the dGPU fails to wake.

### Kokoro TTS

Configured in `mon/sifa/servi/ai-chat/kokoro.nix` and enabled directly in the host assembler at `mon/mehmangi/ayse/estandar.nix` (`drevosim.servi.kokoro.enable = true`).

#### What it is

A self-contained, offline [Kokoro-FastAPI](https://github.com/remsky/Kokoro-FastAPI) v0.5.0 server that exposes an OpenAI-compatible text-to-speech API. It bundles the Kokoro-82M v1.0 model, all voice packs, and the English G2P spaCy model so nothing is downloaded at runtime.

#### Architecture

| Component | Where it lives | Notes |
|-----------|----------------|-------|
| Application source | `/nix/store/...-kokoro-fastapi-0.5.0/lib/python3.13/site-packages/api/src/` | Read-only; updated by `nixos-rebuild` |
| Model weights | `/nix/store/...-kokoro-fastapi-0.5.0/lib/python3.13/site-packages/api/src/models/v1_0/kokoro-v1_0.pth` | ~327 MB; Kokoro-82M v1.0 |
| Voice packs | `/nix/store/...-kokoro-fastapi-0.5.0/lib/python3.13/site-packages/api/src/voices/v1_0/` | 67 `.pt` files |
| English G2P model | Bundled `en_core_web_sm` | Required by misaki; prevents runtime downloads |
| Runtime state | `/var/lib/kokoro-tts/` | Preserved on `/persistent`; mostly empty working directory |
| Temp buffers | Private `/tmp` namespace | Cleaned automatically by the service |

At boot the service loads the model into RAM (~1–1.5 GB), runs a warmup utterance with `af_heart`, and then serves requests. Each request tokenizes the text, loads the requested voice, runs inference, and streams the audio back. **No generated audio is stored on disk.**

> The actual service entry point is `api.src.dashboard_main:app` (see `mon/sifa/servi/ai-chat/dashboard_main.py`). It wraps the upstream FastAPI app with a native ASGI middleware that:
> - copies the bundled voices into the writable `VOICES_DIR` on first run,
> - records the last 100 `/v1/*` requests (caller, payload, status, duration) for the dashboard,
> - exposes `/v1`, `/v1/` 307 redirects to the right endpoints so clients that forget the `/audio/speech` suffix still work.

#### Configuration

- **Bind address / port**: `0.0.0.0:8880` by default (`host`/`port` options).
- **Inference**: CPU by default. GPU is opt-in via `drevosim.servi.kokoro.gpu = true`; it targets the Pascal MX150 using `cudaCapabilities = [ "6.1" ]`.
- **Firewall**: port `8880/tcp` is opened when the service is enabled.

#### OpenAI-compatible endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /v1/models` | Returns the model list (`kokoro`) |
| `GET /v1/audio/voices` | Returns the 67 available voices |
| `POST /v1/audio/speech` | Generates audio from text |
| `GET /health` | Health check |

Example with `curl`:

```bash
# List voices
curl http://127.0.0.1:8880/v1/audio/voices

# Generate English speech
curl http://127.0.0.1:8880/v1/audio/speech \
  -H 'Content-Type: application/json' \
  -d '{"model":"kokoro","input":"Hello from Kokoro.","voice":"af_heart","response_format":"mp3"}' \
  -o hello.mp3

# Generate Portuguese speech
curl http://127.0.0.1:8880/v1/audio/speech \
  -H 'Content-Type: application/json' \
  -d '{"model":"kokoro","input":"Olá, isto é um teste.","voice":"pf_dora","response_format":"mp3"}' \
  -o ola.mp3
```

`response_format` supports the standard OpenAI values: `mp3`, `wav`, `opus`, `aac`, `flac`.

#### Web dashboard

A web UI is bundled into the service and served by the same uvicorn instance at `http://<ayse-ip>:8880/dashboard`. It provides:

- **Speech playground** — type text, pick a voice and format, play/clipboard the result.
- **Voice manager** — list bundled voices, upload new `.pt` voice packs to `VOICES_DIR`, delete custom voices.
- **System status** — live CPU/RAM/VRAM metrics, count of in-flight `/v1/*` requests.
- **API call log** — last 100 `/v1/*` requests with caller identification (SillyTavern, browser, curl, Python), payload preview, status code, duration.

The dashboard is read/write: uploading voices writes to `/var/lib/kokoro-tts/voices` (preserved on `/persistent`), so custom voices survive reboots.

#### Voices

There is a single model (`kokoro`, Kokoro-82M v1.0) and **67 voices**. Voice IDs use a two-letter prefix that indicates language/accent and gender:

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

To preview a voice quickly:

```bash
VOICE=af_alloy
curl http://127.0.0.1:8880/v1/audio/speech \
  -H 'Content-Type: application/json' \
  -d "{\"model\":\"kokoro\",\"input\":\"This is ${VOICE}.\",\"voice\":\"${VOICE}\",\"response_format\":\"mp3\"}" \
  -o /tmp/${VOICE}.mp3
```

#### Client configuration

- **Web dashboard**: `http://<ayse-ip>:8880/dashboard` — built-in playground, voice manager, and API call inspector.
- **SillyTavern** (already configured): `Extensions → TTS → OpenAI`, URL `http://127.0.0.1:8880/v1`, voice `af_heart`.
- **Open WebUI**: set TTS engine to OpenAI-compatible, URL `http://<ayse-ip>:8880/v1`, API key any dummy value, pick a voice.
- **Any OpenAI TTS client**: point it at `http://<ayse-ip>:8880/v1` and use a voice ID from `/v1/audio/voices`.

#### State and persistence

`/var/lib/kokoro-tts` is preserved on `/persistent` so any runtime state survives reboots. In practice the service keeps the model and voices in the Nix store, so the state directory stays small.

### SillyTavern

Configured in `mon/sifa/servi/ai-chat/sillytavern.nix` and enabled directly in the host assembler at `mon/mehmangi/ayse/estandar.nix` (`drevosim.servi.sillytavern.enable = true`).

- [SillyTavern](https://sillytavern.app/) web UI on `http://0.0.0.0:8000`.
- Whitelist allows localhost, IPv6 localhost, and the Tailscale CGNAT range (`100.64.0.0/10`). Whitelist mode is configured by seeding `config.local.yaml` (the upstream yargs parser mis-handles `--listen=1`, so CLI flags are avoided).
- State (`/var/lib/SillyTavern`) preserved on `/persistent`.
- TTS pre-configured to use the local Kokoro service (`http://127.0.0.1:8880/v1`) with the `af_heart` voice.
- Chat backend pre-configured to use the OpenCode Go relay via Cloudflare Worker; the relay access token is stored in `siri/ayse-go-relay.age` and decrypted by agenix, and the fallback model is `minimax-m3`.
- Curated third-party extensions bundled declaratively from flake inputs (CharacterLibrary, TopInfoBar, QuickPersona, PromptInspector, TypingIndicator, Notebook, Objective, Ultimate-ChatAssistant).
- CharacterLibrary's `cl-helper` server plugin enabled; FlareSolverr is started automatically for Cloudflare bypass.
- All requests that hit the bundled Kokoro API show up in the Kokoro dashboard's API call log (the dashboard identifies the caller as "SillyTavern" via the `User-Agent`).

### FTP

Configured in `mon/sifa/servi/ftp.nix` and enabled directly in the host assembler at `mon/mehmangi/ayse/estandar.nix` (`drevosim.servi.ftp.enable = true`).

A read-write [vsftpd](https://security.appspot.com/vsftpd.html) server that exposes `/var/lib/ftp-srv` over plain FTP with **no authentication**. It exists primarily so consoles and other homebrew FTP clients (PlayStation, Xbox, etc.) can browse the host's internal storage without passwords or TLS, but it is general purpose and works with any anonymous-FTP client.

#### Configuration

- **Server**: `vsftpd` v3.x.
- **Anonymous user**: enabled, passwordless (`local_enable = false`, no `pam_service_name`).
- **Bind / control port**: `0.0.0.0:21`.
- **Passive ports**: `30000–30100/tcp` (for data connections on a typical NAT).
- **Filesystem layout** (created on first activation by `systemd.tmpfiles`):

  | Path | Owner | Mode | Purpose |
  |------|-------|------|---------|
  | `/var/lib/ftp-srv` | `root:ftp` | `0755` | Anonymous root, read-only at the server level |
  | `/var/lib/ftp-srv/upload` | `ftp:ftp` | `0755` | Writable drop box for uploads |

  vsftpd refuses to run with a writable anonymous root, so the entire tree is read-only and the only writable spot is the `upload/` subdirectory. Uploads land there and are never auto-cleaned.
- **State and persistence**: `/var/lib/ftp-srv` is preserved on `/persistent` so the FTP root and any uploaded files survive reboots.
- **Firewall**: control port `21/tcp` and the passive range `30000–30100/tcp` are opened when the service is enabled.
- **Tailscale**: not required. The service binds to `0.0.0.0`, so it is reachable over LAN and over Tailscale once Tailscale is added (no extra config needed; the Tailscale CGNAT range `100.64.0.0/10` is just normal traffic to the firewall).
- **No TLS**: TLS is intentionally disabled for maximum compatibility with console homebrew clients. **Do not expose this service to the public internet.**

#### Usage

Any anonymous-FTP client can connect:

```bash
# Browse the root
ftp ftp://ayse.local
# Or from a Tailscale peer:
ftp ftp://100.x.y.z
# Username: anonymous   (or any string)
# Password: <blank, or anything ending in "@">
```

```bash
# Upload a file with curl
curl -T ./myfile.zip ftp://ayse.local/upload/

# List the writable drop box
curl ftp://ayse.local/upload/
```

```bash
# Download a file
curl -o myfile.zip ftp://ayse.local/some/path/myfile.zip
```

Files written into `upload/` are owned by the `ftp` system user and have default umask `022`, so they are world-readable. Move or chmod them before sharing further.

### Gaming

Configured in `mon/sifa/yuxi/`:

- `steam.nix` — `programs.steam` with `gamescopeSession.enable` and `remotePlay.openFirewall`.
- `heroic.nix` — Heroic Games Launcher (Epic, GOG, Amazon Prime Gaming).
- `tul.nix` — `gamescope`, `mangohud`, `protonup-qt`, `protontricks`, and `programs.gamemode`.

Game data is installed under the preserved `~/Games` directory to avoid filling the 3.9 GB tmpfs root.

## Todo / Hardening Notes

- [ ] Deploy SSH keys and set `PasswordAuthentication = false`.
- [ ] Integrate `nix-maid` to manage dotfiles declaratively and reduce the amount of preserved `~/.config` state.
- [ ] Move KDE Plasma configuration from preserved `~/.config` into Nix modules.
- [ ] Decide what else from `/home` should be preserved under `/mnt/data` or via `preservation.nix`.
- [ ] Consider switching from `legacy_580` to the open kernel modules once the hardware supports it (currently blocked by Pascal).
- [ ] The FTP service is plain (no TLS) and unauthenticated; keep it on the LAN/Tailscale only and do not port-forward it.
