# PS4 FTP Mount — Operator's Manual

A practical guide to the persistent FUSE mount of a PlayStation 4's homebrew
FTP server. Read this when you need to push saves to the PS4, pull screenshots
off it, or debug the mount.

The mount lives at **`/mnt/ps4`** on `ayse` and is backed by
[rclone](https://rclone.org/ftp/) talking FTP to a PS4 running GoldHEN (or any
other homebrew FTP payload) at **`192.168.15.200:2121`**.

---

## Table of contents

- [What it is and what it isn't](#what-it-is-and-what-it-isnt)
- [How it works](#how-it-works)
- [Configuration options](#configuration-options)
- [Quick start](#quick-start)
- [Reading and writing files](#reading-and-writing-files)
- [Refreshing the view](#refreshing-the-view)
- [Common tasks](#common-tasks)
- [Cache and performance tuning](#cache-and-performance-tuning)
- [Stability and speed tuning](#stability-and-speed-tuning)
- [Troubleshooting](#troubleshooting)
- [Service management](#service-management)
- [Security and limits](#security-and-limits)

---

## What it is and what it isn't

| This is | This is not |
|---------|-------------|
| A FUSE filesystem at `/mnt/ps4` backed by the PS4's FTP server | A local copy of the PS4's storage — files are not duplicated |
| Read-write by default (you can drag-drop in a file manager) | A general-purpose network share — only the PS4 FTP server is exposed |
| Anonymous FTP, no password, port 2121 | A secure service — FTP credentials and traffic are plain text |
| Started by a systemd service that auto-recovers when the PS4 comes online | A true on-demand automount — the service runs continuously once the PS4 is reachable |

The PS4's internal storage appears under `/mnt/ps4` as if it were a local
folder. Anything you read, write, or delete there is read, written, or
deleted on the PS4.

---

## How it works

```
┌──────────────┐   FUSE    ┌──────────────┐   FTP    ┌──────────────┐
│ File manager │<─────────>│ rclone mount │<────────>│  PS4 GoldHEN │
│ (Dolphin,    │           │ (systemd     │  port    │  FTP server  │
│  Nautilus,   │           │  service)    │  2121    │  192.168.15. │
│  Thunar…)    │           │              │          │  200         │
└──────────────┘           └──────────────┘          └──────────────┘
                                  │
                                  ▼
                          /mnt/ps4
```

- **rclone** is installed by the module and is the only binary the service
  actually runs.
- A thin wrapper at `/etc/rclone-ps4-mount` sets the
  `RCLONE_FTP_PASS` environment variable and then `exec`s rclone. This is
  what gets started by systemd.
- The rclone configuration file at `/etc/rclone-ps4.conf` defines the
  `ps4-ftp:` remote (type, host, port, user). The password is supplied at
  runtime via the env var.
- A systemd service `rclone-ps4.service` runs rclone in the foreground,
  mounts `/mnt/ps4`, and is configured to restart on failure with a 30-second
  delay — so if the PS4 is off, the service keeps retrying quietly.

### Why a service and not a mount unit

`rclone mount` runs in the foreground and never tells systemd it's ready.
When configured as a `fileSystems` mount unit, systemd kills it after 90
seconds (the default `TimeoutStartSec`) and the mount dies. Running it as a
service sidesteps the readiness problem entirely.

### Why `ExecStartPre` and a real `fusermount3` path

A FUSE mount whose userspace process has died leaves a "stale" entry in the
kernel. Reads against a stale mount return `Transport endpoint is not
connected`, and a new mount on the same path fails with `directory already
mounted`. If the previous instance was killed by SIGKILL or ran out of disk
(so `fusermount3` could not run), the stale mount persists and the service
crash-loops on every restart.

The service is therefore self-healing:

- `ExecStartPre` calls `fusermount3 -u /mnt/ps4` (idempotent — no-op if
  nothing is mounted) before each start, so any stale entry from a previous
  crash is cleared automatically.
- `ExecStop` calls `fusermount3 -u /mnt/ps4` on graceful shutdown, so a
  clean stop also unmounts.

Both use the absolute path from the `fuse3` package (`/nix/store/…/bin/fusermount3`),
not `/bin/fusermount3`, which does not exist on NixOS.

### VFS cache location and size cap

rclone's VFS cache lives at **`/mnt/ssd/cache/rclone-ps4/`**, on the
`@cache` btrfs subvolume of the NVMe SSD (see
[`gida/ssd-cache.md`](ssd-cache.md)). It is mounted by disko at boot, and
the rclone service is wired to wait for the mount via `requires =
[ "mnt-ssd-cache.mount" ]` and `after = [ "mnt-ssd-cache.mount" ]`.

The previous location (`/var/cache/rclone-ps4/` on the 3.9 GB tmpfs root)
caused "no space left on device" failures when moving large `.pkg` files
because the 1 GB VFS cache cap is a *target*, not a hard limit, and
the active transfer exceeds it. Moving the cache to the SSD subvolume
gives us ~180 GB of fast scratch space and the cache cap can be raised
to `10G` (set via the `vfsCacheMaxSize` option).

The mount is invoked with `--vfs-cache-max-size=10G` (default) and
`--vfs-cache-max-age=24h`, so the cache can never grow beyond 10 GB
and entries expire after a day.

### Why a password at all

rclone's FTP backend decodes every password source as base64. Even when the
underlying password is empty, rclone still tries to base64-decode it. To
avoid that error, the module pipes `anonymous@` through `rclone obscure` at
build time and stores the result. The `RCLONE_FTP_PASS` env var carries the
obscured string; rclone decodes it back to `anonymous@` at runtime.

If you ever `nix flake update` and the locked rclone version changes, the
obscured string stays valid because the module always uses
`pkgs.rclone` (the locked version) to generate it.

---

## Configuration options

All options live under `drevosim.servi.ftp-ps4.*`. Defaults:

### Connection

| Option | Default | Description |
|--------|---------|-------------|
| `enable` | `false` | Master switch. Set to `true` in `estandar.nix` to enable. |
| `host` | `192.168.15.200` | IP or hostname of the PS4. |
| `port` | `2121` | FTP server port. |
| `mountPoint` | `/mnt/ps4` | Where the PS4 filesystem appears on ayse. |
| `user` | `anonymous` | FTP username. |
| `readOnly` | `false` | If `true`, the mount is read-only. |
| `idleTimeoutSec` | `300` | (legacy) Idle timeout; currently unused because we use a service, not an automount. |

### FTP backend (connection stability)

| Option | Default | Description |
|--------|---------|-------------|
| `disableEpsv` | `true` | Force plain PASV instead of EPSV. The PS4's EPSV often produces unusable data-port allocations. |
| `disableMlsd` | `true` | Force plain LIST instead of MLSD. The PS4's MLSD responses are inconsistent. |
| `ftpConcurrency` | `1` | Number of FTP control connections. The PS4 FTP server is single-threaded; >1 corrupts listings. |
| `timeout` | `30s` | Per-FTP-command timeout. |
| `contimeout` | `30s` | FTP control-connection timeout. |
| `lowLevelRetries` | `20` | How many times to retry a failed FTP command before giving up. |

### Mount and VFS (throughput and accuracy)

| Option | Default | Description |
|--------|---------|-------------|
| `bufferSize` | `64Mi` | In-memory read buffer per open file. Larger = smoother large-file copies. |
| `vfsReadAhead` | `128Mi` | Disk-buffered read-ahead for sequential reads. |
| `transfers` | `4` | Parallel file transfers from the VFS cache. |
| `checkers` | `8` | Parallel directory scans. |
| `dirCacheTime` | `2m` | How long a directory listing is trusted. Lower = more accurate sync. |
| `pollInterval` | `10s` | Backend polling interval (must be < `dirCacheTime`). |
| `vfsCachePollInterval` | `5s` | How often the VFS layer re-checks files for changes. |
| `attrTimeout` | `5s` | Kernel-side attribute cache TTL. Lower = more up-to-date sizes in the file manager. |
| `noChecksum` | `true` | Skip MD5 on every transfer. Faster; TCP already protects against bit errors. |
| `logFile` | `/var/log/rclone-ps4.log` | rclone log path. Empty string disables file logging. |

To change, edit `mon/mehmangi/ayse/estandar.nix`:

```nix
drevosim.servi.ftp-ps4 = {
  enable = true;
  host = "192.168.15.201";        # if the PS4's IP changes
  port = 2121;
  mountPoint = "/mnt/ps4";

  # Performance overrides
  bufferSize = "128Mi";
  vfsReadAhead = "256Mi";
  timeout = "60s";                # be more patient with a slow PS4
  dirCacheTime = "30s";           # more accurate sync
};
```

Then `sudo nixos-rebuild switch --flake .`.

---

## Quick start

1. Make sure the PS4 is on, the GoldHEN FTP payload is loaded, and the
   PS4 is at `192.168.15.200:2121`. (You should see the LED activity when
   FTP is running.)

2. Confirm the service is running:

   ```bash
   systemctl status rclone-ps4
   ```

   You should see `Active: active (running)`.

3. Confirm the mount is live:

   ```bash
   mount | grep ps4
   ```

   Expected: `ps4-ftp{...}: on /mnt/ps4 type fuse.rclone ...`

4. Browse it:

   ```bash
   ls /mnt/ps4
   ```

   You should see the PS4's top-level directories: `user/`, `data/`, `system/`,
   `mnt/`, etc.

5. Or open `/mnt/ps4` in your file manager (Dolphin, Nautilus, Thunar…).

---

## Reading and writing files

### Copy a file to the PS4

```bash
# Single file
cp ~/my-save.sav /mnt/ps4/user/savedata/...

# A whole directory
cp -r ~/screenshots /mnt/ps4/photo/

# With rsync for resumable transfers
rsync -avP ~/large-pkg.pkg /mnt/ps4/data/
```

The file appears on the PS4 filesystem immediately (subject to rclone's
write cache — usually well under a second for small files).

### Copy a file from the PS4

```bash
# Single file
cp /mnt/ps4/user/.../screenshot.png ~/Pictures/

# A whole directory tree
rsync -avP /mnt/ps4/photo/ ~/Pictures/from-ps4/
```

### Delete a file on the PS4

```bash
rm /mnt/ps4/data/old-game.pkg
```

This sends a `DELE` over FTP and the file is gone on the PS4.

### Move a file on the PS4

```bash
mv /mnt/ps4/data/temp.pkg /mnt/ps4/user/
```

### Make a new directory on the PS4

```bash
mkdir /mnt/ps4/data/ayse-uploads
```

### File manager drag-and-drop

All of the above work via drag-and-drop in any file manager. **However**,
rclone's FUSE layer does not implement partial-write / random-access; every
write is uploaded as a single `STOR` command. That is fine for typical
files but means:
- You cannot reliably append to a file in the middle.
- A failed upload leaves a partial file on the PS4 — clean it up with
  `rm` and try again.

---

## Refreshing the view

rclone caches directory listings for 30 minutes
(`--dir-cache-time=30m`). If you change files on the PS4 directly (for
example, from the PS4's own file manager), the changes will not show up
on ayse until the cache expires or you force a refresh.

### Force a refresh

```bash
sudo systemctl restart rclone-ps4
```

This unmounts and remounts the FUSE filesystem. It takes 1–3 seconds.

### If the mount is wedged

```bash
sudo fusermount3 -u /mnt/ps4
sudo systemctl restart rclone-ps4
```

### Confirm the cache is the problem

```bash
# This lists the cached contents
ls /mnt/ps4/user

# Modify a file on the PS4 directly
# ...

# This may still show the old state
ls /mnt/ps4/user

# This shows the new state
sudo systemctl restart rclone-ps4 && ls /mnt/ps4/user
```

---

## Common tasks

### Push a PS4 save from your PC to the PS4

1. Plug the save into a file manager on your PC.
2. If the PC and ayse are on the same network, share it over SSH
   (ayse runs `openssh`):

   ```bash
   scp ./my-save.sav eter@ayse:/tmp/
   ```

3. From ayse:

   ```bash
   sudo cp /tmp/my-save.sav /mnt/ps4/user/savedata/<title-id>/
   sudo chown 1000:1000 /mnt/ps4/user/savedata/<title-id>/my-save.sav
   ```

   (The PS4's save-game daemon expects specific UIDs; `1000:1000` is the
   typical user partition. If the save doesn't appear in-game, try the
   PS4's own permissions view to confirm.)

4. On the PS4, re-scan / refresh the saves in the game's options menu.

### Pull screenshots off the PS4

```bash
mkdir -p ~/Pictures/ps4
rsync -av --progress /mnt/ps4/photo/ ~/Pictures/ps4/
```

### Install a large `.pkg` on the PS4

The PS4's package installer expects `.pkg` files in specific locations.
The most common is to put them in `/data/` and install via the debug
package installer (if available). With this mount:

```bash
sudo cp /path/to/game.pkg /mnt/ps4/data/
```

Then use the PS4's debug package installer (`*enable-debug-package-installer*`
in GoldHEN settings) and point it at `/data/game.pkg`.

### Browse the entire PS4 filesystem

```bash
ls /mnt/ps4
# user/   data/   system/   system_data/   mnt/   update/   ...
```

These correspond to the standard PS4 partitions.

---

## Cache and performance tuning

The mount is configured for "feels-good browsing" with the following
options in the rclone command line:

| Flag | Value | Effect |
|------|-------|--------|
| `--vfs-cache-mode` | `writes` | Buffers writes in `/mnt/ssd/cache/rclone-ps4/` until uploaded, but does NOT prefetch reads. `full` mode would prefill the cache with browsed files (slow on LAN); `writes` is the right default for the PS4. |
| `--vfs-cache-max-size` | `1G` | Hard cap on the cache directory. Prevents a stalled upload from filling the 3.9 GB tmpfs root. |
| `--vfs-cache-max-age` | `24h` | Cache entries older than this are evicted. |
| `--vfs-cache-poll-interval` | `30s` | How often rclone polls the FTP server to see if its cached state is still valid. |
| `--dir-cache-time` | `30m` | How long a directory listing is trusted before being re-fetched. |
| `--poll-interval` | `30s` | Backend-level polling (FTP). |
| `--timeout` | `10s` | Per-command timeout. |
| `--contimeout` | `10s` | Connection timeout. |
| `--allow-other` | enabled | Lets any local user (not just root) access the mount. |

### If you want immediate writes (slower browsing)

Edit `mon/sifa/servi/ftp/ps4.nix` and change:

```nix
--vfs-cache-mode=full
```

to

```nix
--vfs-cache-mode=minimal
```

`minimal` flushes writes as soon as the file is closed and only caches
reads of recently-listed directories. Then `sudo nixos-rebuild switch`.

### If you want lower latency on directory changes

Change `--dir-cache-time=30m` to `--dir-cache-time=1m` (or `30s`). This
makes the mount more "live" but increases the number of FTP `LIST`
commands per minute.

---

## Stability and speed tuning

The defaults are tuned for the PS4 over a typical LAN. If you see frequent
disconnects, "stale" listings, or slow large-file copies, this section
explains what each knob does and how to trade off.

### Why the PS4 is flaky in the first place

The PS4's homebrew FTP server (GoldHEN et al.) is a minimal implementation
that was never meant to be hammered by a long-lived FUSE mount. Three
specific things go wrong:

1. **EPSV produces broken data-port allocations.** rclone defaults to
   Extended Passive Mode; the PS4's EPSV response is often unusable
   (the IP/port the server returns is wrong or the data port is
   firewalled). Plain `PASV` works reliably.
2. **MLSD responses are truncated or malformed.** rclone's default FTP
   listing is MLSD (RFC 3659), which the PS4 claims to support but
   implements inconsistently. Plain `LIST` is universal and faster here.
3. **A single PS4 FTP session can only do one thing at a time.** Opening
   multiple data connections concurrently corrupts the listings.
   `concurrency = 1` is mandatory.

The module forces all three defaults (`disableEpsv`, `disableMlsd`,
`ftpConcurrency = 1`) and you should not change them unless you know
the PS4 has been updated.

### Tuning for accurate sync

If you want changes on the PS4 to show up in your file manager
within a few seconds:

```nix
drevosim.servi.ftp-ps4 = {
  dirCacheTime = "30s";          # re-list directories every 30s
  vfsCachePollInterval = "2s";   # re-check file contents every 2s
  attrTimeout = "2s";            # file manager refreshes size/mtime every 2s
  pollInterval = "5s";           # backend polling
};
```

Trade-off: every 2–5 seconds rclone issues FTP `STAT` or `LIST`
commands, so very large directories (>1000 entries) will generate a
steady background load. For the PS4's top-level directories this is
fine.

### Tuning for large-file throughput

If you copy multi-gigabyte `.pkg` files and they feel slow:

```nix
drevosim.servi.ftp-ps4 = {
  bufferSize = "128Mi";          # in-memory read buffer per open file
  vfsReadAhead = "256Mi";        # disk-buffered read-ahead
  transfers = 4;                 # parallel uploads from the VFS cache
  noChecksum = true;             # skip MD5 (LAN is already TCP-checksummed)
  timeout = "60s";               # be patient with the PS4's slow CPU
  lowLevelRetries = 30;          # don't give up on transient hiccups
};
```

Trade-off: `bufferSize × open files` is held in RAM. 128 MiB × 4
open files = 512 MiB of resident memory, which is fine on a typical
desktop. `vfsReadAhead` lives on the VFS cache disk on the SSD
subvolume (10 GB cap by default).

### Tuning for a flaky network

If the mount disconnects and reconnects frequently:

```nix
drevosim.servi.ftp-ps4 = {
  timeout = "60s";
  contimeout = "60s";
  lowLevelRetries = 50;          # very forgiving
  dirCacheTime = "5m";           # reduce background LIST traffic
  vfsCachePollInterval = "30s";
};
```

Combined with the `ExecStartPre` self-healing in the service unit,
this lets rclone ride out long PS4 stalls without taking the whole
mount down.

### Reading the log

If something goes wrong, the log file is the first place to look:

```bash
tail -f /var/log/rclone-ps4.log
journalctl -u rclone-ps4 -f
```

rclone logs every FTP command at `INFO` level. To see the raw FTP
session for debugging, set `logFile` to a path and temporarily add
`--log-level=DEBUG` by editing the wrapper in
`mon/sifa/servi/ftp/ps4.nix` (the option is not exposed because the
log becomes very verbose).

The log is ephemeral (lives on the tmpfs root) and disappears on
reboot. journald's own record of the service is persistent for the
current boot session.

### Bench: copy a large file

To see what your current tuning actually does:

```bash
# Make a 500 MiB test file
dd if=/dev/urandom of=/tmp/bigfile.bin bs=1M count=500 status=none

# Time the copy (writes to the VFS cache, uploads in background)
time cp /tmp/bigfile.bin /mnt/ps4/data/

# Watch the rclone log to see the actual upload speed
tail -f /var/log/rclone-ps4.log
```

A healthy connection over gigabit Ethernet to a wired PS4 should
see 40–80 MB/s. Wi-Fi is usually 10–25 MB/s. If you see
substantially less, try increasing `bufferSize` and `vfsReadAhead`
and re-test.

---

## Troubleshooting

### "ls: cannot access '/mnt/ps4': Transport endpoint is not connected"

The FUSE filesystem is dead. The rclone process probably crashed.

```bash
sudo systemctl status rclone-ps4
sudo journalctl -u rclone-ps4 -n 30 --no-pager
sudo systemctl restart rclone-ps4
```

### "ls: Input/output error" on first access

rclone is still establishing the FTP connection. Wait 5–10 seconds and
try again. If it persists:

```bash
# Verify the PS4 is reachable
curl -v --max-time 5 ftp://192.168.15.200:2121/

# If that works, restart the mount
sudo systemctl restart rclone-ps4
```

### "mount: unknown filesystem type 'fuse'"

The kernel module is missing or FUSE is not enabled. On ayse this is
expected to work out of the box. If you ever see this:

```bash
sudo modprobe fuse
```

### Write fails with "permission denied"

The mount is read-only. Either:

- You set `readOnly = true` in the module — change it to `false` and
  rebuild.
- The PS4 FTP server denies writes to that path. Try writing to
  `/mnt/ps4/data/` (usually the most permissive).

### "Failed to create file system: NewFS decrypt password: base64 decode failed"

This is a version mismatch between the obscured password (baked at build
time) and the running rclone. It should not happen on ayse because the
build uses the locked nixpkgs' rclone. If you see it after a manual
`nix flake update` that changed rclone, rebuild:

```bash
sudo nixos-rebuild switch --flake .
```

The module regenerates the obscured password to match the new rclone.

### "Mounting timed out. Terminating." (legacy fstab error)

This was the old behaviour when the mount was configured via
`fileSystems` instead of the systemd service. If you see it, you are
running a configuration that pre-dates the service-based switch. The
current `mon/sifa/servi/ftp/ps4.nix` uses `systemd.services."rclone-ps4"`
and does not have this problem.

### Performance is poor

Try the cache tuning options above. Also check the PS4's network
connection: a Wi-Fi-connected PS4 will be much slower than Ethernet.

---

## Service management

The mount is managed by `rclone-ps4.service`, a normal systemd unit.

### Useful commands

```bash
# Status
systemctl status rclone-ps4

# Start / stop / restart
sudo systemctl start rclone-ps4
sudo systemctl stop rclone-ps4
sudo systemctl restart rclone-ps4

# Enable / disable at boot
sudo systemctl enable rclone-ps4
sudo systemctl disable rclone-ps4

# Live logs
journalctl -u rclone-ps4 -f

# Last 50 log lines
journalctl -u rclone-ps4 -n 50 --no-pager
```

### Manual mount (debugging)

If you want to run rclone by hand to see errors directly:

```bash
sudo systemctl stop rclone-ps4
sudo fusermount3 -u /mnt/ps4 2>/dev/null
sudo RCLONE_FTP_PASS='<obscured-from-config>' \
  rclone mount \
    --config=/etc/rclone-ps4.conf \
    --cache-dir=/mnt/ssd/cache/rclone-ps4 \
    --vfs-cache-mode=writes \
    --allow-other \
    ps4-ftp: /mnt/ps4
```

The obscured password is whatever `/etc/rclone-ps4-mount` sets. You can
read it with:

```bash
grep RCLONE_FTP_PASS /etc/rclone-ps4-mount
```

### Disable the mount

```nix
# In mon/mehmangi/ayse/estandar.nix
drevosim.servi.ftp-ps4.enable = false;
```

Then `sudo nixos-rebuild switch --flake .`. The service will be removed
and `/mnt/ps4` will be an empty directory (or whatever you put there).

---

## Security and limits

- **Plain FTP, no encryption.** Everything sent to the PS4 is in clear.
  Keep this on the LAN (and Tailscale) only. Do not port-forward 2121.
- **Anonymous, no password.** Any device on the network can read, write,
  and delete files on the PS4. Treat the PS4 as a public file share.
- **No partial writes.** rclone uploads the whole file in one go. Don't
  try to edit large files in place from ayse.
- **No file locking semantics.** Two writers can clobber each other. Don't
  run parallel uploads of the same file.
- **The PS4's filesystem is fragile.** Don't randomly delete from
  `/mnt/ps4/system/`, `/mnt/ps4/system_data/`, or `/mnt/ps4/update/`
  unless you know what you're doing. The `/data/` and `/user/` partitions
  are safer for experimentation.

---

## Quick reference

```bash
# Is it up?
systemctl is-active rclone-ps4 && mount | grep ps4

# Refresh (drop cache)
sudo systemctl restart rclone-ps4

# Push a file
cp thing.pkg /mnt/ps4/data/

# Pull a file
cp /mnt/ps4/photo/IMG_0001.png ~/Pictures/

# Delete on PS4
rm /mnt/ps4/data/old-game.pkg

# Browse
ls /mnt/ps4

# Speed test
dd if=/dev/urandom of=/tmp/bigfile.bin bs=1M count=500 status=none
time cp /tmp/bigfile.bin /mnt/ps4/data/

# Watch live transfer
tail -f /var/log/rclone-ps4.log
```

If something doesn't work, check `journalctl -u rclone-ps4 -n 50` and
`tail -f /var/log/rclone-ps4.log` first — most problems are visible
in one of them.
