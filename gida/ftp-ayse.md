# Anonymous FTP Server (ayse) — Operator's Manual

A practical guide to the read-write anonymous FTP server running on `ayse`.
Read this when you need to host files for a console (PS4, Xbox, etc.) or any
other client that expects a password-less FTP endpoint.

The server is [vsftpd](https://security.appspot.com/vsftpd.html), bound to
`0.0.0.0:21` (passive data ports `30000–30100`), with the FTP root at
`/var/lib/ftp-srv` and a writable drop box at `/var/lib/ftp-srv/upload/`.

---

## Table of contents

- [What it is and what it isn't](#what-it-is-and-what-it-isnt)
- [How it works](#how-it-works)
- [Configuration options](#configuration-options)
- [Quick start](#quick-start)
- [Connecting](#connecting)
- [Uploading and downloading](#uploading-and-downloading)
- [Refreshing / inspecting uploads](#refreshing--inspecting-uploads)
- [Common tasks](#common-tasks)
- [Troubleshooting](#troubleshooting)
- [Service management](#service-management)
- [Security and limits](#security-and-limits)

---

## What it is and what it isn't

| This is | This is not |
|---------|-------------|
| A read-write anonymous FTP server with no authentication | A secure service — FTP is plain text and the login is anonymous |
| A general-purpose file drop box for any client that speaks FTP | A high-performance share — it's a single-threaded FTP server tuned for compatibility, not throughput |
| Designed for console homebrew clients (PS4, Xbox, etc.) and trusted LAN peers | A replacement for SFTP/SCP/SSH — use those for anything sensitive |
| Read-only at the server root, with a single writable `upload/` subdirectory | A general write-anywhere share — vsftpd refuses to run with a writable anonymous root, so the only writable spot is `upload/` |

---

## How it works

```
┌──────────────┐   FTP/21   ┌──────────────────┐   disk   ┌──────────────────┐
│   Client     │<──────────>│ vsftpd           │<────────>│ /var/lib/ftp-srv │
│ (PS4, curl,  │  + passive │ (static user)    │          │  ├── upload/     │
│  FileZilla…) │  30000–    │ anonymous only,  │          │  └── (read-only) │
│              │  30100     │ no password      │          │                  │
└──────────────┘            └──────────────────┘          └──────────────────┘
                                    │
                                    ▼
                       preserved on /persistent
```

- **vsftpd** is the daemon. The NixOS module enables it with `anonymousUser
  = true`, `anonymousUserNoPassword = true`, and `writeEnable = true`.
- The anonymous root is `/var/lib/ftp-srv`, created by `systemd.tmpfiles`
  with mode `0755` owned by `root:ftp`. The directory is traversable but
  not writable at the root.
- The `upload/` subdirectory is created with mode `0755` owned by `ftp:ftp`
  so the anonymous user can write to it.
- `/var/lib/ftp-srv` is preserved on `/persistent` via the `preservation`
  module, so uploaded files survive reboots.
- The control port is `21/tcp`; the passive data range is
  `30000–30100/tcp`. Both are opened in the firewall when the service is
  enabled.
- The service binds to `0.0.0.0`, so it is reachable from LAN and from
  Tailscale once Tailscale is added.

### Why a writable `upload/` subdirectory and not a writable root

vsftpd has a hard-coded safety check: it refuses to start if the
anonymous root is world-writable. The conventional workaround is to make
the root read-only and put a single writable subdirectory inside it. This
prevents clients from writing files anywhere they like (which would be a
disaster for a shared console drop box) while still allowing uploads to
land in a predictable place.

---

## Configuration options

All options live under `drevosim.servi.ftp-ayse.*`. Defaults:

| Option | Default | Description |
|--------|---------|-------------|
| `enable` | `false` | Master switch. Set to `true` in `estandar.nix` to enable. |
| `port` | `21` | Control port. |
| `passiveMinPort` | `30000` | Lowest passive-mode data port. |
| `passiveMaxPort` | `30100` | Highest passive-mode data port. |
| `openFirewall` | `true` | Open the control port and passive range in the firewall. |
| `stateDir` | `/var/lib/ftp-srv` | (read-only) The anonymous root. |

To change any of these, edit `mon/mehmangi/ayse/estandar.nix`:

```nix
drevosim.servi.ftp-ayse = {
  enable = true;
  port = 21;
  passiveMinPort = 30000;
  passiveMaxPort = 30100;
};
```

Then `sudo nixos-rebuild switch --flake .`.

---

## Quick start

1. Confirm the service is running:

   ```bash
   systemctl status vsftpd
   ```

   You should see `Active: active (running)`.

2. Confirm the ports are listening:

   ```bash
   sudo ss -tlnp | grep -E ':21\s|:300'
   ```

   Expected: `*:21` owned by `vsftpd`, plus listeners in `30000–30100`.

3. Check the filesystem layout:

   ```bash
   ls -la /var/lib/ftp-srv
   ```

   Expected:

   ```text
   drwxr-xr-x root ftp  ./
   drwxr-xr-x root ftp  ../
   drwxr-xr-x ftp  ftp  upload/
   ```

4. Test a local connection:

   ```bash
   curl ftp://127.0.0.1/
   ```

   Expected: `upload` directory listed.

---

## Connecting

Any standard FTP client works. No password is required; the username
`anonymous` (or any string) is accepted.

### From the command line (curl)

```bash
# Browse the root
curl ftp://ayse.local/
# Or by IP
curl ftp://192.168.1.x/

# With Tailscale
curl ftp://100.x.y.z/
```

### Interactive (`ftp` CLI)

```bash
ftp ayse.local
```

At the prompts:

```text
Name: anonymous
Password: <just press Enter>
```

### FileZilla or any GUI client

- **Host**: `ayse.local` (or IP / Tailscale IP)
- **Port**: `21`
- **Protocol**: **FTP** (not FTPS, not SFTP)
- **Encryption**: **Use plain FTP / insecure**
- **Username**: `anonymous`
- **Password**: blank (or anything ending in `@`)

### From a PS4 (GoldHEN or other homebrew FTP client)

```
Host: ayse.local
Port: 21
Username: anonymous
Password: <blank>
```

Browse into `upload/` to write files. Read from anywhere else.

---

## Uploading and downloading

### Upload to `upload/`

```bash
# Single file
curl -T ./myfile.zip ftp://ayse.local/upload/

# Multiple files (curl sends each as STOR)
for f in *.zip; do curl -T "$f" ftp://ayse.local/upload/; done

# From a GUI client: drag files into the upload/ folder
```

### List the upload directory

```bash
curl ftp://ayse.local/upload/
```

### Download from anywhere

```bash
# Single file
curl -o myfile.zip ftp://ayse.local/some/path/myfile.zip

# Whole directory
wget -r -np ftp://ayse.local/some/path/
```

### Delete an upload

There is no `DELE` from anonymous by default. To remove an uploaded file
from ayse:

```bash
sudo rm /var/lib/ftp-srv/upload/myfile.zip
```

The `anon_other_write_enable=YES` directive in the module does allow
anonymous `DELE` inside `upload/`, so most clients can also right-click →
delete in the GUI, or:

```bash
curl -X "DELE myfile.zip" ftp://ayse.local/upload/
```

### Rename an upload

```bash
curl -X "RNFR old.zip" -X "RNTO new.zip" ftp://ayse.local/upload/
```

(Most GUI clients handle this transparently.)

---

## Refreshing / inspecting uploads

The server has no directory cache — listings are always live. But the
filesystem on ayse is on the persistent Btrfs partition, so changes made
on ayse (like `sudo rm /var/lib/ftp-srv/upload/foo.zip`) are immediately
visible to clients on the next `LIST`.

### Check what's been uploaded

```bash
ls -la /var/lib/ftp-srv/upload/
```

### Watch uploads in real time

```bash
watch -n1 'ls -la /var/lib/ftp-srv/upload/'
```

Or with `inotifywait` if you prefer event-driven:

```bash
inotifywait -m /var/lib/ftp-srv/upload/
```

### Disk usage

```bash
du -sh /var/lib/ftp-srv
du -sh /var/lib/ftp-srv/upload/*
```

Nothing is auto-cleaned. Uploads accumulate until you remove them.

---

## Common tasks

### Let a PS4 dump a save onto ayse

1. On the PS4, open the homebrew FTP client and connect to `ayse.local`.
2. Browse to `upload/`.
3. Copy the save (or any file) from `/user/savedata/...` into `upload/`.
4. On ayse:

   ```bash
   ls -la /var/lib/ftp-srv/upload/
   sudo mv /var/lib/ftp-srv/upload/CUSA00001-save.sav /persistent/games/
   ```

### Host a large file for LAN peers to grab

1. Copy the file into the read-only part of the FTP root (requires root):

   ```bash
   sudo cp /path/to/big-thing.iso /var/lib/ftp-srv/distros/big-thing.iso
   sudo chown root:ftp /var/lib/ftp-srv/distros/big-thing.iso
   sudo chmod 0755 /var/lib/ftp-srv/distros
   sudo chmod 0644 /var/lib/ftp-srv/distros/big-thing.iso
   ```

2. Tell your peers:

   ```bash
   ftp://ayse.local/distros/big-thing.iso
   ```

3. They can `curl -O` it, or use a GUI client.

### Restrict uploads to a single user (read-write, password)

vsftpd supports per-user logins, but this module does not enable them
(`localEnable = false`). If you need authenticated upload, see the
vsftpd man page and add a second module — but the intended use case for
this server is "no auth, console-friendly".

---

## Troubleshooting

### "Connection refused" on port 21

The service is not running, or the firewall is blocking the port.

```bash
systemctl status vsftpd
sudo ss -tlnp | grep :21
sudo iptables -L -n | grep 21
```

### "Failed to retrieve directory listing"

Active mode is being attempted, or the passive ports are blocked. Most
modern clients default to passive; force it explicitly:

```bash
curl --ftp-skip-pasv-ip ftp://ayse.local/
```

If that hangs, the passive range is blocked. On ayse:

```bash
sudo ss -tlnp | grep vsftpd
```

should show listeners in `30000–30100`. If not, restart the service.

### "553 Could not create file."

Uploads work in `upload/` but not elsewhere. This is intentional — the
root is read-only. If you need to write elsewhere, see the FTP
"Common tasks" section above.

### Uploads are world-readable

Uploads are created with umask `022` (set in the module), so they end
up mode `0644`. That's deliberate for a shared drop box. If you need
restricted access, `chmod 0600` after the upload completes, or move
the file out of `/var/lib/ftp-srv/upload/`.

### Service won't start after a rebuild

Check the journal:

```bash
journalctl -u vsftpd -n 30 --no-pager
```

Common causes:

- `/var/lib/ftp-srv` has wrong ownership (must be `root:ftp`, mode
  `0755`).
- `/var/lib/ftp-srv/upload` has wrong ownership (must be `ftp:ftp`,
  mode `0755`).
- The firewall was reset and the passive range is no longer open.

To fix the directory layout, run:

```bash
sudo systemd-tmpfiles --create
```

### Performance is poor

vsftpd is single-process; each transfer is sequential. For large
transfers, consider a different service (Samba, SFTP) or run multiple
concurrent curl commands to saturate the link.

---

## Service management

The server runs as the standard `vsftpd.service` unit.

### Useful commands

```bash
# Status
systemctl status vsftpd

# Start / stop / restart
sudo systemctl start vsftpd
sudo systemctl stop vsftpd
sudo systemctl restart vsftpd

# Live logs
journalctl -u vsftpd -f

# Last 50 log lines
journalctl -u vsftpd -n 50 --no-pager
```

### Generated config

The vsftpd config is rendered at
`/nix/store/<hash>-vsftpd.conf`. Inspect it with:

```bash
cat /etc/vsftpd.conf
```

or

```bash
systemctl cat vsftpd | grep -i config
```

### Disable the service

```nix
# In mon/mehmangi/ayse/estandar.nix
drevosim.servi.ftp-ayse.enable = false;
```

Then `sudo nixos-rebuild switch --flake .`. The service will be
disabled; the `/var/lib/ftp-srv` directory will be left in place
(preserved on `/persistent`).

---

## Security and limits

- **Plain FTP, no encryption.** Everything sent is in clear. Keep this
  on the LAN / Tailscale only. Do not port-forward 21 to the internet.
- **Anonymous, no password.** Any device on the network can read
  everything and write into `upload/`. Treat ayse as a public file
  share.
- **The FTP root is read-only.** The only writable area is
  `/var/lib/ftp-srv/upload/`. Clients cannot write elsewhere.
- **Uploads are world-readable** (umask `022`). Tighten with `chmod` if
  needed.
- **No upload size limit, no auto-cleanup.** Uploads accumulate on the
  persistent Btrfs partition. Monitor disk usage:

  ```bash
  df -h /persistent
  du -sh /var/lib/ftp-srv
  ```

- **No transfer encryption.** Use SFTP/SCP/SSH for anything sensitive.

---

## Quick reference

```bash
# Status
systemctl status vsftpd

# Test local connection
curl ftp://127.0.0.1/

# Upload
curl -T thing.zip ftp://ayse.local/upload/

# List uploads
curl ftp://ayse.local/upload/
ls -la /var/lib/ftp-srv/upload/

# Download
curl -O ftp://ayse.local/path/to/file

# Delete on ayse
sudo rm /var/lib/ftp-srv/upload/file.zip

# Logs
journalctl -u vsftpd -n 50
```

If something doesn't work, check `journalctl -u vsftpd -n 50` first.
