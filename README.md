# NixOS — Impermanent Setup

This repository contains the declarative NixOS configuration for a single machine running an **impermanent** (ephemeral root) setup with [Disko](https://github.com/nix-community/disko) and [preservation](https://github.com/nix-community/preservation).

## Overview

- **Root filesystem (`/`)**: `tmpfs` created fresh on every boot.
- **`/nix`**: Dedicated Btrfs subvolume on the SSD, persisted across reboots.
- **`/persistent`**: Btrfs subvolume on the SSD for system state preserved by `preservation`.
- **`/home`**: Separate spinning disk (HDD) formatted with Btrfs + zstd compression, persisted normally.
- **Desktop**: COSMIC (Wayland) with cosmic-greeter.

## File Layout

| File | Purpose |
|------|---------|
| `flake.nix` | Flake inputs (`nixpkgs`, `disko`, `preservation`) and the `nixos` system output. |
| `configuration.nix` | Main system configuration: boot, networking, desktop, user, packages. |
| `disko.nix` | Disk partitioning and filesystem layout. **Review disk devices before applying.** |
| `preservation.nix` | Paths on the ephemeral root that are bind-mounted from `/persistent`. |
| `hardware-configuration.nix` | Auto-generated kernel modules and CPU microcode settings. |
| `flake.lock` | Locked flake input revisions. |

## Disks

Configured in `disko.nix`:

- `/dev/nvme0n1` — SSD (boot, swap, `/nix`, `/persistent`)
  - `ESP` (1 GiB, vfat, `/boot`)
  - `swap` (16 GiB)
  - `root` (remainder, Btrfs)
    - subvolume `nix` → `/nix`
    - subvolume `persistent` → `/persistent`
- `/dev/sda` — HDD (`/home`)
  - single Btrfs partition with zstd compression

> **Warning:** `disko.nix` references specific device names. Always double-check these paths on the target hardware before running any destructive Disko command.

## Rebuilding the System

From this directory:

```bash
sudo nixos-rebuild switch --flake .
```

Or explicitly:

```bash
sudo nixos-rebuild switch --flake .#nixos
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
3. Verify/adjust disk device names in `disko.nix`.
4. Run Disko to partition and format:

   ```bash
   sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode destroy,format,mount ./disko.nix
   ```

5. Install NixOS:

   ```bash
   sudo nixos-install --flake .#nixos
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
