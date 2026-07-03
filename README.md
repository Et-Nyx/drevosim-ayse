# NixOS — Impermanent Setup

This repository contains the declarative NixOS configuration for a single machine (`ayse`) running an **impermanent** (ephemeral root) setup with [Disko](https://github.com/nix-community/disko) and [preservation](https://github.com/nix-community/preservation).

The flake is organized in a dendritic (tree-like) structure inspired by [Drevosim](flakes/drevosim-ayse/README.md): a single flake root feeds a trunk of module directories, which split into hosts, features, helpers, and secrets.

## Overview

- **Root filesystem (`/`)**: `tmpfs` created fresh on every boot.
- **`/nix`**: Dedicated Btrfs subvolume on the SSD, persisted across reboots.
- **`/persistent`**: Btrfs subvolume on the SSD for system state preserved by `preservation`.
- **`/home`**: Separate spinning disk (HDD) formatted with Btrfs + zstd compression, persisted normally.
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
│   │           └── preservation.nix # preservation rules for the ephemeral root
│   └── sifa/              # feature modules
│       ├── kolor/         # theming & customization
│       │   └── tul.nix
│       ├── kuflu/         # security & login (ly, sddm)
│       │   ├── ly.nix
│       │   ├── sddm.nix
│       │   ├── tul.nix
│       │   └── faylu/     # raw config files (filtered from import-tree)
│       │       └── ly.ini
│       ├── medya/         # audio / video
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
│           └── tul.nix
├── offolo/                # offline / external build dependencies
│   └── rill.nix           # vendored Zig dependencies for rill
└── yongu/                 # helper functions
    ├── monlari.nix        # recursive NixOS-module collector
    └── parseIni.nix       # pure-Nix INI parser for faylu/ files
```

## Disks

Configured in `mon/mehmangi/ayse/nukleus/disko.nix`:

- `/dev/nvme0n1` — SSD (boot, swap, `/nix`, `/persistent`)
  - `ESP` (1 GiB, vfat, `/boot`)
  - `swap` (16 GiB)
  - `root` (remainder, Btrfs)
    - subvolume `nix` → `/nix`
    - subvolume `persistent` → `/persistent`
- `/dev/sda` — HDD (`/home`)
  - single Btrfs partition with zstd compression

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

- `/etc/nixos` is symlinked to `/home/eter/nixos` via `systemd.tmpfiles.rules` so the canonical config always lives on the persistent home disk.
- Flakes and `nix-command` are enabled.
- Automatic GC keeps generations newer than 7 days.
- SSH is enabled with password authentication (intended to be switched to key-only once keys are deployed).
- Locale is `pt_BR.UTF-8` and timezone is `America/Recife`.

## Todo / Hardening Notes

- [ ] Deploy SSH keys and set `PasswordAuthentication = false`.
