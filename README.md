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

| File / Directory | Purpose |
|------------------|---------|
| `flake.nix` | Flake inputs and flake-parts + import-tree entry point. |
| `flake.lock` | Locked flake input revisions. |
| `mon/` | Module tree (imported recursively by import-tree). |
| `mon/parts.nix` | flake-parts `systems` configuration. |
| `mon/basi.nix` | Shared base options (`drevosim.userName`, nix settings, GC, unfree). |
| `yongu/monlari.nix` | Recursive NixOS-module collector used by the host assembler. |
| `mon/sifa/` | Feature modules. |
| `mon/sifa/kolor/` | Theming & customization. |
| `mon/sifa/kuflu/` | Security & login (ly, swaylock, waylock). |
| `mon/sifa/medya/` | Audio / video (pipewire, media utilities). |
| `mon/sifa/mesa/` | Window managers, compositors & desktops (Plasma, river, canoe, rill). |
| `mon/sifa/produti/` | Productivity tools. |
| `mon/sifa/programa/` | General programs (fuzzel, simple utilities, browsers). |
| `mon/sifa/servi/` | System services (networkmanager, openssh, mako, polkit). |
| `mon/sifa/terminal/` | Terminal emulators, shells & generic CLI tools. |
| `mon/sifa/yuxi/` | Gaming. |
| `mon/mehmangi/ayse/` | Host configuration for machine `ayse`. |
| `mon/mehmangi/ayse/estandar.nix` | Host assembler (defines `.#ayse`). |
| `mon/mehmangi/ayse/ogarli.nix` | User configuration. |
| `mon/mehmangi/ayse/loka.nix` | Locale, timezone, and keymaps. |
| `mon/mehmangi/ayse/nukleus/` | Core host configuration. |
| `mon/mehmangi/ayse/nukleus/estrutur.nix` | Hostname and host-specific structure. |
| `mon/mehmangi/ayse/nukleus/hardwer.nix` | Hardware/kernel configuration. |
| `mon/mehmangi/ayse/nukleus/xoru.nix` | Bootloader configuration. |
| `mon/mehmangi/ayse/nukleus/disko.nix` | Disk partitioning and filesystem layout. |
| `mon/mehmangi/ayse/nukleus/preservation.nix` | Preservation rules for the ephemeral root. |

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
