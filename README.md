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
│       │   ├── networkmanager.nix
│       │   ├── openssh.nix
│       │   ├── mako.nix
│       │   ├── polkit.nix
│       │   ├── tul.nix
│       │   ├── kokoro.nix # Kokoro TTS API server
│       │   ├── sillytavern.nix # SillyTavern web UI + extensions
│       │   └── faylu/     # raw config files (filtered from import-tree)
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
│   └── ayse-eter-pasalexi.age
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
- Preserved system state includes `/etc/ssh`, `/var/lib/bluetooth` (pairing keys), `/var/lib/NetworkManager/system-connections`, `/var/lib/nixos` (user/group database), `/var/lib/kokoro-tts` (TTS service state), and `/var/lib/SillyTavern` (SillyTavern data).
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

Configured in `mon/sifa/servi/kokoro.nix` and enabled for `ayse` in `mon/mehmangi/ayse/kokoro.nix`:

- Self-contained [Kokoro-FastAPI](https://github.com/remsky/Kokoro-FastAPI) v0.5.0 package bundled with model weights (`hexgrad/Kokoro-82M`) and all voice packs.
- OpenAI-compatible HTTP API at `http://0.0.0.0:8880` (bind address and port are configurable).
- CPU inference by default; GPU mode is opt-in via `drevosim.servi.kokoro.gpu = true` and targets the Pascal MX150 with `cudaCapabilities = [ "6.1" ]`.
- English (`af_*`, `am_*`, etc.) and Portuguese (`pf_*`, `pm_*`) voices are included; clients select the voice per request.
- `/var/lib/kokoro-tts` is preserved on `/persistent` so state survives reboots.
- Firewall port 8880 is opened when the service is enabled.

### SillyTavern

Configured in `mon/sifa/servi/sillytavern.nix` and enabled for `ayse` in `mon/mehmangi/ayse/sillytavern.nix`:

- [SillyTavern](https://sillytavern.app/) web UI on `http://0.0.0.0:8000`.
- Whitelist allows localhost, IPv6 localhost, and the Tailscale CGNAT range (`100.64.0.0/10`).
- State (`/var/lib/SillyTavern`) preserved on `/persistent`.
- TTS pre-configured to use the local Kokoro service (`http://127.0.0.1:8880/v1`) with the `af_heart` voice.
- Chat backend pre-configured to use the OpenCode Go relay via Cloudflare Worker; the relay access token is stored in `siri/ayse-go-relay.age` and decrypted by agenix.
- Curated third-party extensions bundled declaratively (CharacterLibrary, TopInfoBar, QuickPersona, PromptInspector, TypingIndicator, Notebook, Objective, Ultimate-ChatAssistant).
- CharacterLibrary's `cl-helper` server plugin enabled; FlareSolverr is started automatically for Cloudflare bypass.

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
