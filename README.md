# NixOS — Impermanent Setup

This repository contains the declarative NixOS configuration for a single machine (`ayse`) running an **impermanent** (ephemeral root) setup with [Disko](https://github.com/nix-community/disko) and [preservation](https://github.com/nix-community/preservation).

The flake is organized in a dendritic (tree-like) structure inspired by [Drevosim](flakes/drevosim-ayse/README.md): a single flake root feeds a trunk of module directories, which split into hosts, features, helpers, and secrets.

This `README.md` covers the **what and where** — the file layout, the disks, the rebuild/update workflow, and one-paragraph summaries of every feature. The **how and why** — operator's manuals for the more intricate modules — live in [`gida/`](gida/).

## Overview

- **Root filesystem (`/`)**: `tmpfs` created fresh on every boot.
- **`/home`**: `tmpfs`, recreated fresh on every boot.
- **`/nix`**: Dedicated Btrfs subvolume on the SSD, persisted across reboots.
- **`/persistent`**: Btrfs partition on the HDD for all system and user state preserved by `preservation`.
- **Desktop**: KDE Plasma 6 with SDDM.

See [`gida/preservation.md`](gida/preservation.md) for the full rules and what is and isn't preserved.

## File Layout

```text
.
├── flake.nix              # flake-parts + import-tree entry point
├── flake.lock             # locked input revisions
├── README.md              # this file
├── gida/                  # operator's manuals (one per major module)
│   ├── ftp-ayse.md
│   ├── ftp-ps4.md
│   ├── kokoro.md
│   ├── sillytavern.md
│   ├── nvidia.md
│   ├── preservation.md
│   └── ssd-cache.md      # /mnt/ssd/cache SSD subvolume pattern
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
│   │           ├── disko.nix      # disk partitioning & filesystem layout (incl. @cache SSD subvolume → /mnt/ssd/cache)
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
│       │   ├── ai-chat/   # AI chat services
│       │   │   ├── kokoro.nix        # Kokoro TTS API server + dashboard
│       │   │   ├── sillytavern.nix   # SillyTavern web UI + extensions
│       │   │   ├── dashboard.html    # Kokoro web dashboard UI
│       │   │   └── dashboard_main.py # Kokoro dashboard middleware
│       │   ├── ftp/                  # FTP services
│       │   │   ├── ayse.nix          # anonymous FTP server (vsftpd)
│       │   │   └── ps4.nix           # PS4 FTP client mount (rclone FUSE)
│       │   └── faylu/                # raw config files (filtered from import-tree)
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
- Bluetooth is enabled (`hardware.bluetooth`) with `powerOnBoot = true` and `bluez` in `systemPackages`.

### NVIDIA (Optimus / PRIME)

Configured in `mon/mehmangi/ayse/nukleus/nvidia.nix`. The host (`ayse`) is a Dell Inspiron 7580 with Intel UHD 630 (iGPU) and NVIDIA GeForce MX150 (GP108M, Pascal). The dGPU is wired to a 3D controller class (no display), so PRIME render-offload is the only way to use it.

- `hardware.nvidia.package` is pinned to `legacy_580` (Pascal support was dropped in the 595+ production branch).
- `hardware.nvidia.open = false` (Pascal is not supported by the open kernel modules).
- `prime.offload.enable = true` with `prime-run` exposed at `/run/current-system/sw/bin`.
- `prime.reverseSync.enable = true` to render dGPU output on the iGPU's display.
- Global `__NV_PRIME_RENDER_OFFLOAD` / `__GLX_VENDOR_LIBRARY_NAME` / `__VK_LAYER_NV_optimus` env vars are set in `environment.sessionVariables` so user-launched apps prefer the dGPU.
- `cudaCapabilities = [ "6.1" ]` (Pascal compute capability).
- `boot.kernelParams = [ "pcie_aspm=off" "nvidia-drm.modeset=1" ]` and a udev rule force the dGPU out of D3cold at boot.

An `igpu` specialisation is defined for fallback: it blacklists all nvidia kernel modules, forces `services.xserver.videoDrivers = [ "modesetting" ]`, and unsets the PRIME env vars. Boot it from the systemd-boot menu if the dGPU fails to wake.

See [`gida/nvidia.md`](gida/nvidia.md) for the full operator's manual (boot-time GPU wake, the `igpu` specialisation, CUDA, troubleshooting).

### Kokoro TTS

Configured in `mon/sifa/servi/ai-chat/kokoro.nix` and enabled directly in the host assembler at `mon/mehmangi/ayse/estandar.nix` (`drevosim.servi.kokoro.enable = true`).

A self-contained, offline [Kokoro-FastAPI](https://github.com/remsky/Kokoro-FastAPI) v0.5.0 server that exposes an OpenAI-compatible text-to-speech API. It bundles the Kokoro-82M v1.0 model, all 67 voice packs, and the English G2P spaCy model so nothing is downloaded at runtime. Binds to `0.0.0.0:8880` and serves a built-in web dashboard at `/dashboard`.

CPU by default; CUDA opt-in via `drevosim.servi.kokoro.gpu = true` (Pascal `6.1`).

See [`gida/kokoro.md`](gida/kokoro.md) for the full operator's manual (API reference, all 67 voices, dashboard features, GPU mode, client configuration).

### SillyTavern

Configured in `mon/sifa/servi/ai-chat/sillytavern.nix` and enabled directly in the host assembler (`drevosim.servi.sillytavern.enable = true`).

[SillyTavern](https://sillytavern.app/) web UI on `http://0.0.0.0:8000`, with whitelist access (localhost + Tailscale `100.64.0.0/10`). TTS is pre-configured to use the local Kokoro service with the `af_heart` voice; the chat backend is pre-configured to use the OpenCode Go relay via Cloudflare Worker (token in `siri/ayse-go-relay.age`); the fallback model is `minimax-m3`. Eight curated third-party extensions are bundled from flake inputs.

See [`gida/sillytavern.md`](gida/sillytavern.md) for the full operator's manual (whitelist, extensions, relay configuration, troubleshooting).

### Anonymous FTP server

Configured in `mon/sifa/servi/ftp/ayse.nix` and enabled at `drevosim.servi.ftp-ayse.enable = true`.

A read-write [vsftpd](https://security.appspot.com/vsftpd.html) server with no authentication, designed for console homebrew FTP clients and LAN file sharing. Binds `0.0.0.0:21` with passive ports `30000–30100`. The anonymous root is `/var/lib/ftp-srv` (read-only); the only writable subdirectory is `upload/`. State preserved on `/persistent`. **Do not expose to the public internet.**

See [`gida/ftp-ayse.md`](gida/ftp-ayse.md) for the full operator's manual (connection examples, upload/download, troubleshooting).

### PS4 FTP mount

Configured in `mon/sifa/servi/ftp/ps4.nix` and enabled at `drevosim.servi.ftp-ps4.enable = true`.

A persistent FUSE mount of the PS4's homebrew FTP server at `192.168.15.200:2121`, exposed at `/mnt/ps4` on ayse. Backed by [rclone](https://rclone.org/ftp/) and a systemd service that auto-recovers when the PS4 comes online. Read-write by default.

See [`gida/ftp-ps4.md`](gida/ftp-ps4.md) for the full operator's manual (architecture, file operations, cache tuning, troubleshooting).

### Gaming

Configured in `mon/sifa/yuxi/`:

- `steam.nix` — `programs.steam` with `gamescopeSession.enable` and `remotePlay.openFirewall`.
- `heroic.nix` — Heroic Games Launcher (Epic, GOG, Amazon Prime Gaming).
- `tul.nix` — `gamescope`, `mangohud`, `protonup-qt`, `protontricks`, and `programs.gamemode`.

Game data is installed under the preserved `~/Games` directory to avoid filling the 3.9 GB tmpfs root.

## Operator's manuals (`gida/`)

The verbose "how and why" for each major module lives in its own file under
[`gida/`](gida/). Each guide mirrors the same structure: what it is / isn't,
how it works, configuration options, quick start, usage, troubleshooting,
service management, security and limits, and a quick reference.

| Guide | Module |
|-------|--------|
| [`gida/ftp-ayse.md`](gida/ftp-ayse.md) | `mon/sifa/servi/ftp/ayse.nix` |
| [`gida/ftp-ps4.md`](gida/ftp-ps4.md) | `mon/sifa/servi/ftp/ps4.nix` |
| [`gida/kokoro.md`](gida/kokoro.md) | `mon/sifa/servi/ai-chat/kokoro.nix` |
| [`gida/sillytavern.md`](gida/sillytavern.md) | `mon/sifa/servi/ai-chat/sillytavern.nix` |
| [`gida/nvidia.md`](gida/nvidia.md) | `mon/mehmangi/ayse/nukleus/nvidia.nix` |
| [`gida/preservation.md`](gida/preservation.md) | `mon/mehmangi/ayse/nukleus/preservation.nix` |
| [`gida/ssd-cache.md`](gida/ssd-cache.md) | `mon/mehmangi/ayse/nukleus/disko.nix` (the `@cache` subvolume) |

## Todo / Hardening Notes

- [ ] Deploy SSH keys and set `PasswordAuthentication = false`.
- [ ] Integrate `nix-maid` to manage dotfiles declaratively and reduce the amount of preserved `~/.config` state.
- [ ] Move KDE Plasma configuration from preserved `~/.config` into Nix modules.
- [ ] Decide what else from `/home` should be preserved under `/mnt/data` or via `preservation.nix`.
- [ ] Consider switching from `legacy_580` to the open kernel modules once the hardware supports it (currently blocked by Pascal).
- [ ] The anonymous FTP server is plain (no TLS) and unauthenticated; keep it on the LAN/Tailscale only and do not port-forward it. Same for the PS4 FTP mount — it is plain FTP.
- [ ] **Move Firefox profile + cache to `/mnt/ssd/cache/firefox/`** — the ephemeral `~/.cache` is wiped on every boot (cold cache, slow first-page-load) and the profile rides the slow HDD via `preservation.nix`'s `~/.config` rule. Both move to the new SSD subvolume for speed and persistence. Module: `mon/sifa/programa/firefox.nix`. Migration: copy existing profile from `/persistent/home/eter/.config/mozilla/` to `/mnt/ssd/cache/firefox/profile/` before the first rebuild.
- [x] **Write `gida/ssd-cache.md`** — done. Documents the `/mnt/ssd/cache` SSD subvolume pattern (introduced in `disko.nix`) and lists which services consume it. Notes the difference from `/persistent` (HDD) and the 4 GB tmpfs root.
- [ ] **Audit other `~/.cache` consumers for SSD migration**: `~/.cache/nix` (~70 MB, nix store cache, wiped on every boot), `~/.cache/mesa_shader_cache` (~2.5 MB), `~/.cache/opencode` (~3 MB). Same fix applies but needs `nix-maid` or a module that overrides `XDG_CACHE_HOME` / `NIX_CACHE_HOME`. Different scope from a per-service fix.
- [ ] **Move Steam / Heroic game data to a dedicated SSD path** (e.g. `/mnt/ssd/games` or a subdir of `/mnt/ssd/cache/`). Currently installs to the preserved `~/Games` on the HDD; the SSD has 180+ GB free and game load times would improve dramatically. Requires declaring a new subvolume in `disko.nix` and pointing `programs.steam` at it. Larger scope.
- [ ] **PS4 FTP** — news pending, see user notes.
