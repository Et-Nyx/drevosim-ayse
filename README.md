# NixOS — Traditional Setup

This repository contains the declarative NixOS configuration for a single machine (`ayse`) running a **traditional** persistent-root setup with [Disko](https://github.com/nix-community/disko). The root filesystem is a regular Btrfs subvolume on the SSD; everything on disk survives reboots without any special persistence plumbing.

The flake is organized in a dendritic (tree-like) structure inspired by [Drevosim](flakes/drevosim-ayse/README.md): a single flake root feeds a trunk of module directories, which split into hosts, features, helpers, and secrets.

This `README.md` covers the **what and where** — the file layout, the disks, the rebuild/update workflow, and one-paragraph summaries of every feature. The **how and why** — operator's manuals for the more intricate modules — live in [`gida/`](gida/).

## Overview

- **Root filesystem (`/`)**: Btrfs subvolume `@root` on the SSD — fully persistent, no tmpfs.
- **`/home`**: regular directories on the root filesystem.
- **`/nix`**: Dedicated Btrfs subvolume on the SSD.
- **`/storage`**: Btrfs partition on the HDD for bulk user data.
- **Desktop**: KDE Plasma 6 with SDDM.
- **Networking**: Tailscale mesh VPN (on by default) with tailnet-only service exposure.

## File Layout

```text
.
├── flake.nix              # flake-parts + import-tree entry point
├── flake.lock             # locked input revisions
├── README.md              # this file
├── gida/                  # operator's manuals (one per major module)
│   ├── adguard.md
│   ├── calibre.md
│   ├── ftp-ayse.md
│   ├── ftp-ps4-client.md
│   ├── kokoro.md
│   ├── sillytavern.md
│   ├── tailscale.md
│   └── nvidia.md
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
│   │           ├── powercap.nix   # thermald + RAPL CPU power caps (65 W adapter)
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
│       ├── medya/         # audio / video / media
│       │   ├── bluetooth.nix
│       │   ├── calibre.nix      # Calibre e-book manager (desktop)
│       │   ├── pipewire.nix
│       │   ├── grayjay.nix
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
│       │   ├── basa.nix         # base productivity packages
│       │   ├── git.nix          # git + declarative ~/.gitconfig & ~/.ssh/config (nix-maid)
│       │   └── tul.nix
│       ├── programa/      # general programs
│       │   ├── firefox.nix      # Firefox with enterprise policies (uBlock, DuckDuckGo)
│       │   ├── waydroid.nix     # Android virtualization
│       │   ├── fuzzel.nix
│       │   ├── tul.nix
│       │   └── faylu/     # raw config files (filtered from import-tree)
│       │       └── fuzzel.ini
│       ├── servi/         # system services
│       │   ├── adguard.nix        # AdGuard Home tailnet DNS adblocker
│       │   ├── calibre.nix      # Calibre content server
│       │   ├── network.nix
│       │   ├── openssh.nix
│       │   ├── mako.nix
│       │   ├── polkit.nix
│       │   ├── tailscale.nix    # Tailscale VPN + Serve routes + tailnet firewall
│       │   ├── tul.nix
│       │   ├── ai-chat/   # AI chat services
│       │   │   ├── kokoro.nix        # Kokoro TTS API server + dashboard
│       │   │   ├── sillytavern.nix   # SillyTavern web UI + extensions
│       │   │   ├── dashboard.html    # Kokoro web dashboard UI
│       │   │   └── dashboard_main.py # Kokoro dashboard middleware
│       │   └── ftp/                  # FTP services
│       │       ├── ayse.nix          # anonymous FTP server (vsftpd)
│       │       └── ps4-client.nix    # PS4 FTP client (FileZilla + lftp aliases)
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
│   ├── ayse-go-relay.age      # OpenCode Go relay access token
│   ├── ayse-sillytavern.age   # SillyTavern admin password
│   └── ayse-tailscale-auth.age # Tailscale auth key
└── yongu/                 # helper functions
    ├── monlari.nix        # recursive NixOS-module collector
    └── parseIni.nix       # pure-Nix INI parser for faylu/ files
```

## Disks

Configured in `mon/mehmangi/ayse/nukleus/disko.nix`:

- `/dev/nvme0n1` — SSD (root, boot, swap, `/nix`)
  - `ESP` (1 GiB, vfat, `/boot`)
  - `swap` (16 GiB, hibernate resume device)
  - `root` (remainder, Btrfs)
    - subvolume `@root` → `/` (persistent root; the whole OS, `/etc`, `/home`, `/var` live here)
    - subvolume `nix` → `/nix`
- `/dev/sda` — HDD (`/storage`)
  - single Btrfs partition with zstd compression
  - holds bulk user data (`Downloads`, `Music`, `Videos`) symlinked back to home to save SSD space

> **Warning:** The Disko configuration references specific device names. Always double-check these paths on the target hardware before running any destructive Disko command.
>
> **Note:** The SSD Btrfs filesystem still carries unmounted legacy subvolumes from the former impermanent setup (`@persistent` and its `@persistent-ro-backup` read-only snapshot, plus the old `persistent` and `@cache` subvolumes). They can be deleted once the traditional layout has been verified.

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

6. Reboot, restore state (users' home data, `/etc/ssh` host keys), set the user password, and continue using `nixos-rebuild switch` as normal.

## Notable Configuration Details

- The flake checkout lives directly at `/etc/nixos` on the persistent root.
- Flakes and `nix-command` are enabled.
- Automatic GC keeps generations newer than 7 days.
- SSH is enabled with password authentication (intended to be switched to key-only once keys are deployed).
- Locale is `pt_BR.UTF-8` and timezone is `America/Recife`.
- User and root passwords are stored as age-encrypted hashes in `siri/` and decrypted at boot by `agenix`.
- `users.mutableUsers = false` so `/etc/shadow` always matches the NixOS configuration.
- Stale Chromium lock files and KWallet data are cleaned on every boot.
- Bluetooth is enabled (`hardware.bluetooth`) with `powerOnBoot = true` and `bluez` in `systemPackages`.

### Power capping (thermald + RAPL)

Configured in `mon/mehmangi/ayse/nukleus/powercap.nix`. The Dell Inspiron 7580 runs AC-only with a 65 W adapter, and factory turbo spikes (PL2 up to 44 W) combined with the dGPU (25 W) and the rest of the system exceeded the adapter's capacity, causing instant shutdowns. `services.thermald` monitors temperatures as a safety net, and a oneshot systemd service (`intel-rapl-cap`) caps the CPU at boot: PL1 (sustained) 15 W, PL2 (burst) 25 W — 25 + 25 + ~14 = 64 W, just under the adapter limit. The `intel_rapl_common` and `intel_rapl_msr` kernel modules are loaded at boot.

### Tailscale

Configured in `mon/sifa/servi/tailscale.nix` and enabled **by default** (`drevosim.servi.tailscale.enable` defaults to `true`).

[Tailscale](https://tailscale.com/) mesh VPN with the auth key managed by agenix (`siri/ayse-tailscale-auth.age`). Web services are reachable only over the tailnet: ports 8000 (SillyTavern) and 8880 (Kokoro TTS API) are opened on the `tailscale0` interface only, and Tailscale Serve proxies them to valid HTTPS URLs at `https://ayse.<tailnet>.ts.net:<port>`. The `ports` and `serve` options merge across modules, so feature modules can add their own entries without clobbering the defaults.

See [`gida/tailscale.md`](gida/tailscale.md) for the full operator's manual.

### Firefox

Configured in `mon/sifa/programa/firefox.nix` and enabled by default. Mozilla Firefox with enterprise policies: telemetry, studies, Pocket, and onboarding messaging disabled; DuckDuckGo as the default search engine; `pt-BR` language pack; and force-installed extensions (uBlock Origin, Return YouTube Dislikes, SponsorBlock) pinned to the navbar. Cache directories are provisioned via tmpfiles rules.

### Waydroid

Configured in `mon/sifa/programa/waydroid.nix` and enabled by default (`drevosim.programa.waydroid.enable`). Android container virtualization via `virtualisation.waydroid` for running Android apps on the Plasma desktop.

### Productivity tools & nix-maid

Configured in `mon/sifa/produti/`. `git.nix` installs git and manages `~/.gitconfig` and `~/.ssh/config` (GitLab SSH key) declaratively through [nix-maid](https://github.com/nix-community/nix-maid) (`users.users.eter.maid`), reducing hand-managed dotfile state. `basa.nix` provides the base productivity package set.

### NVIDIA (Optimus / PRIME)

Configured in `mon/mehmangi/ayse/nukleus/nvidia.nix`. The host (`ayse`) is a Dell Inspiron 7580 with Intel UHD 630 (iGPU) and NVIDIA GeForce MX150 (GP108M, Pascal). The dGPU is wired to a 3D controller class (no display), so PRIME render-offload is the only way to use it.

- `hardware.nvidia.package` is pinned to `legacy_580` (Pascal support was dropped in the 595+ production branch).
- `hardware.nvidia.open = false` (Pascal is not supported by the open kernel modules).
- `prime.offload.enable = true` with `prime-run` exposed at `/run/current-system/sw/bin`.
- `prime.reverseSync.enable = true` to render dGPU output on the iGPU's display.
- Global environment session variables are NOT set so that everyday applications default to the power-efficient Intel iGPU.
- `cudaCapabilities = [ "6.1" ]` (Pascal compute capability).
- `boot.kernelParams = [ "pcie_aspm=off" "nvidia-drm.modeset=1" ]` and a udev rule force the dGPU out of D3cold at boot.

See [`gida/nvidia.md`](gida/nvidia.md) for the full operator's manual (boot-time GPU wake, CUDA, troubleshooting).

### Kokoro TTS

Configured in `mon/sifa/servi/ai-chat/kokoro.nix` and enabled directly in the host assembler at `mon/mehmangi/ayse/estandar.nix` (`drevosim.servi.kokoro.enable = true`).

A self-contained, offline [Kokoro-FastAPI](https://github.com/remsky/Kokoro-FastAPI) v0.5.0 server that exposes an OpenAI-compatible text-to-speech API. It bundles the Kokoro-82M v1.0 model, all 67 voice packs, and the English G2P spaCy model so nothing is downloaded at runtime. Binds to `0.0.0.0:8880` and serves a built-in web dashboard at `/dashboard`.

CPU by default; CUDA opt-in via `drevosim.servi.kokoro.gpu = true` (Pascal `6.1`). The API runs with two workers so a long speech request doesn't block other clients (~2.2 GB RAM total for the two model copies).

See [`gida/kokoro.md`](gida/kokoro.md) for the full operator's manual (API reference, all 67 voices, dashboard features, GPU mode, client configuration).

### SillyTavern

Configured in `mon/sifa/servi/ai-chat/sillytavern.nix` and enabled directly in the host assembler (`drevosim.servi.sillytavern.enable = true`).

[SillyTavern](https://sillytavern.app/) web UI on `http://0.0.0.0:8000`, with whitelist access (localhost + Tailscale `100.64.0.0/10`) and password-protected multi-user login (the admin account handle is configurable via `drevosim.servi.sillytavern.adminHandle`, set to `exdunyayen` in `estandar.nix`; the password lives in `siri/ayse-sillytavern.age` and is seeded at startup). TTS is pre-configured to use the local Kokoro service with the `af_heart` voice; the chat backend is pre-configured to use the OpenCode Go relay via Cloudflare Worker (token in `siri/ayse-go-relay.age`); the fallback model is `deepseek-v4-flash`. Eight curated third-party extensions are bundled from flake inputs.

See [`gida/sillytavern.md`](gida/sillytavern.md) for the full operator's manual (whitelist, extensions, relay configuration, troubleshooting).

### AdGuard Home (Tailnet DNS Adblocker)

Configured in `mon/sifa/servi/adguard.nix` and enabled at `drevosim.servi.adguard.enable = true`.

[AdGuard Home](https://github.com/AdguardTeam/AdGuardHome) listening on `127.0.0.1:53` + the Tailscale IP (`100.75.243.95:53`) — port 53 is only open on the `tailscale0` interface. The Tailscale admin console points the tailnet's global nameserver at it (*Override local DNS*), so every connected device (phone, laptop) gets DNS-level ad blocking with no per-device setup; the host filters itself through tailscaled's `100.100.100.100` stub. Upstreams are encrypted DoH (Cloudflare/Google) — pointed at public resolvers so no resolver loop forms. The dashboard is proxied through Tailscale Serve at `https://ayse.tailfcc763.ts.net:3000`; the YAML is declaratively bootstrapped with two filter lists (AdGuard DNS filter, OISD Small) and then owned by the dashboard.

See [`gida/adguard.md`](gida/adguard.md) for the full operator's manual (admin-console setup, first login, allowlisting, bypassing culprits like Android Private DNS, troubleshooting).

### Anonymous FTP server

Configured in `mon/sifa/servi/ftp/ayse.nix` and enabled at `drevosim.servi.ftp-ayse.enable = true`.

A read-write [vsftpd](https://security.appspot.com/vsftpd.html) server with no authentication, designed for console homebrew FTP clients and LAN file sharing. Binds `0.0.0.0:21` with passive ports `30000–30100`. The anonymous root is `/var/lib/ftp-srv` (read-only); the only writable subdirectory is `upload/`. **Do not expose to the public internet.**

See [`gida/ftp-ayse.md`](gida/ftp-ayse.md) for the full operator's manual (connection examples, upload/download, troubleshooting).

### PS4 FTP client

Configured in `mon/sifa/servi/ftp/ps4-client.nix` and enabled at `drevosim.servi.ftp-ps4-client.enable = true`.

A client-side complement to the anonymous FTP server: [FileZilla](https://filezilla-project.org/) for GUI transfers plus `lftp` shell aliases (`ps4-ls`, `ps4-push`, `ps4-pull`, `ps4-ftp`) targeting the PS4's FTP server at `192.168.15.200:2121` for fast console homebrew file management.

See [`gida/ftp-ps4-client.md`](gida/ftp-ps4-client.md) for the full operator's manual.

### Grayjay

Configured in `mon/sifa/medya/grayjay.nix` and enabled by default. The [Grayjay](https://grayjay.app/) desktop media app with settings declaratively re-applied on every launch (changes made in the Grayjay UI are reverted on the next rebuild + restart; override `drevosim.medya.grayjay.settings` to change defaults). The firewall is opened for LAN sync by default.

### Calibre

Configured in `mon/sifa/medya/calibre.nix` (desktop app) and `mon/sifa/servi/calibre.nix` (content server), with the server enabled at `drevosim.servi.calibre.enable = true`.

The [Calibre](https://calibre-ebook.com/) e-book manager (GUI + `calibre-server`) with the library symlinked to `/storage/home/eter/Biblioteca do calibre` on the HDD — the same pattern as `Downloads`/`Music`/`Videos` — so books live on the roomy HDD. The localized folder name matches Calibre's default under the `pt_BR` locale. The content server binds `0.0.0.0:8080` with the web UI at `/` and an [OPDS](https://opds.io/) catalog at `/opds` for reader apps; it runs as `eter` so the GUI and server share the same library and settings. **Do not port-forward 8080 to the public internet.**

See [`gida/calibre.md`](gida/calibre.md) for the full operator's manual (web UI, OPDS, library on the HDD, troubleshooting).



### Gaming

Configured in `mon/sifa/yuxi/`:

- `steam.nix` — `programs.steam` with `gamescopeSession.enable` and `remotePlay.openFirewall`.
- `heroic.nix` — Heroic Games Launcher (Epic, GOG, Amazon Prime Gaming).
- `tul.nix` — `gamescope`, `mangohud`, `protonup-qt`, `protontricks`, and `programs.gamemode`.

Game data is installed under `~/Games` on the SSD for fast loading performance.

## Operator's manuals (`gida/`)

The verbose "how and why" for each major module lives in its own file under
[`gida/`](gida/). Each guide mirrors the same structure: what it is / isn't,
how it works, configuration options, quick start, usage, troubleshooting,
service management, security and limits, and a quick reference.

| Guide | Module |
|-------|--------|
| [`gida/adguard.md`](gida/adguard.md) | `mon/sifa/servi/adguard.nix` |
| [`gida/calibre.md`](gida/calibre.md) | `mon/sifa/medya/calibre.nix`, `mon/sifa/servi/calibre.nix` |
| [`gida/ftp-ayse.md`](gida/ftp-ayse.md) | `mon/sifa/servi/ftp/ayse.nix` |
| [`gida/ftp-ps4-client.md`](gida/ftp-ps4-client.md) | `mon/sifa/servi/ftp/ps4-client.nix` |
| [`gida/kokoro.md`](gida/kokoro.md) | `mon/sifa/servi/ai-chat/kokoro.nix` |
| [`gida/sillytavern.md`](gida/sillytavern.md) | `mon/sifa/servi/ai-chat/sillytavern.nix` |
| [`gida/tailscale.md`](gida/tailscale.md) | `mon/sifa/servi/tailscale.nix` |
| [`gida/nvidia.md`](gida/nvidia.md) | `mon/mehmangi/ayse/nukleus/nvidia.nix` |

## Todo / Hardening Notes

- [ ] Deploy SSH keys and set `PasswordAuthentication = false`.
- [x] Integrate `nix-maid` to manage dotfiles declaratively and reduce the amount of hand-managed `~/.config` state (done for git config in `produti/git.nix`).
- [ ] Move KDE Plasma configuration from `~/.config` into Nix modules.
- [ ] Consider switching from `legacy_580` to the open kernel modules once the hardware supports it (currently blocked by Pascal).
- [ ] The anonymous FTP server is plain (no TLS) and unauthenticated; keep it on the LAN/Tailscale only and do not port-forward it.
- [ ] **Delete the legacy Btrfs subvolumes** (`@persistent`, `@persistent-ro-backup`, `persistent`, `@cache`) once the traditional layout has been verified, reclaiming ~25 GiB on the SSD.
- [ ] **Consider moving Steam / Heroic games to a dedicated path if needed** — Currently `~/Games` is kept on the SSD for fast loading performance, but can be moved to `/storage/Games` on the HDD if space becomes constrained.
- [ ] **Audit other `~/.cache` consumers for SSD migration** — `~/.cache/nix`, etc.
