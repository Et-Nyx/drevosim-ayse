# Calibre — Operator's Manual

A practical guide to the Calibre e-book manager and its content server on
`ayse`. Read this when you need to manage your e-book library, serve it to
your phone/tablet over the LAN, or troubleshoot either piece.

Calibre is split across two Nix modules:

- `mon/sifa/medya/calibre.nix` — the desktop GUI app (`drevosim.medya.calibre`).
- `mon/sifa/servi/calibre.nix` — the content server service
  (`drevosim.servi.calibre`), enabled in the host assembler.

---

## Table of contents

- [What it is and what it isn't](#what-it-is-and-what-it-isnt)
- [How it works](#how-it-works)
- [Configuration options](#configuration-options)
- [Quick start](#quick-start)
- [The desktop app](#the-desktop-app)
- [The content server](#the-content-server)
- [Library on the HDD](#library-on-the-hdd)
- [Troubleshooting](#troubleshooting)
- [Service management](#service-management)
- [Security and limits](#security-and-limits)
- [Quick reference](#quick-reference)

---

## What it is and what it isn't

| This is | This is not |
|---------|-------------|
| A desktop e-book manager (import, convert, edit metadata, read) | A cloud e-book service — the library is a local folder on the HDD |
| A lightweight web server (calibre-server) that serves your library over HTTP/OPDS | A managed multi-user service — it runs as `eter` with no authentication |
| The canonical source of truth for your book collection | A document store — it's a Calibre library, not a generic file dump |

The content server is an optional convenience: the GUI works fully offline.

---

## How it works

```
┌──────────────┐   GUI        ┌────────────────┐   disk   ┌──────────────────────┐
│  Desktop app │─────────────▶│ calibre        │<────────>│ /storage/home/eter/  │
│  (as eter)   │              │ (as eter)      │          │ Biblioteca do calibre │
└──────────────┘              └────────────────┘          │   ├─ metadata.db     │
                                                     ┌───▶│   ├─ author/         │
┌──────────────┐   HTTP/8080  ┌──────────────────┐   │    │   └─ book/           │
│ Phone/tablet │<────────────▶│ calibre-server   │───┘    └──────────────────────┘
│ (browser /   │  + OPDS      │ (systemd, eter)  │           Btrfs on /dev/sda
│  calibre-web)│              └──────────────────┘
└──────────────┘
```

- **Desktop app** — the `calibre` package from nixpkgs. On first launch it
  asks for a library folder; point it at `~/Biblioteca do calibre`.
- **Library** — `~/Biblioteca do calibre` is a symlink (created by
  `systemd.tmpfiles`) to `/storage/home/eter/Biblioteca do calibre` on the HDD, the
  same pattern as `Downloads`/`Music`/`Videos`. The library survives reboots
  because the HDD partition is persistent; `/home` is tmpfs.
- **Content server** — a systemd service runs
  `calibre-server --host 0.0.0.0 --port 8080 --with-library <library>` as
  `eter`, so the server reads and writes the exact same library and
  `~/.config/calibre` settings as the GUI. No permission juggling.

---

## Configuration options

### Desktop app (`drevosim.medya.calibre.*`)

| Option | Default | Description |
|--------|---------|-------------|
| `enable` | `true` | Install Calibre and set up the library symlink. |
| `libraryDir` | `/storage/home/eter/Biblioteca do calibre` | Where the library lives on the HDD. |

### Content server (`drevosim.servi.calibre.*`)

| Option | Default | Description |
|--------|---------|-------------|
| `enable` | `false` | Master switch, set to `true` in `estandar.nix`. |
| `host` | `0.0.0.0` | Bind address. `127.0.0.1` restricts to this machine. |
| `port` | `8080` | Content server port. |
| `openFirewall` | `true` | Open the port in the firewall. |
| `libraryDir` | `/storage/home/eter/Biblioteca do calibre` | Library served by the server. Keep in sync with the desktop option. |

To change any of these, edit `mon/mehmangi/ayse/estandar.nix`:

```nix
drevosim.servi.calibre = {
  enable = true;
  host = "0.0.0.0";
  port = 8080;
};
```

Then `sudo nixos-rebuild switch --flake .`.

---

## Quick start

1. Confirm the server is running:

   ```bash
   systemctl status calibre-server
   ```

2. Confirm the port is listening:

   ```bash
   sudo ss -tlnp | grep :8080
   ```

3. Confirm the library symlink:

   ```bash
   ls -la /home/eter/ | grep Calibre
   # -> /home/eter/Biblioteca do calibre -> /storage/home/eter/Biblioteca do calibre
   ```

4. Open the server in a browser: `http://ayse.local:8080/`

5. Launch the desktop app: `calibre` (or from the application menu).

---

## The desktop app

Launch `calibre` from the application menu or a terminal. On first run it
asks where your library lives — choose `~/Biblioteca do calibre` (already
symlinked to the HDD).

Typical workflows:

- **Import books** — drag `.epub`/`.mobi`/`.pdf` files into the window or
  use **Add books → Add books from folders**. Files are copied into the
  library structure on the HDD.
- **Convert** — right-click a book → **Convert books → Convert individually**
  (`.azw3` ↔ `.epub`, etc.).
- **Edit metadata** — right-click → **Edit metadata**, or hit `E`.
- **Send to device** — **Send to device → Send to main memory** when a
  reader/phone is plugged in.

> **Note:** Calibre keeps its settings in `~/.config/calibre` and the app's
> preview data under `~/Biblioteca do calibre`. On this impermanent setup,
> `~/.config` is preserved across reboots (see `gida/preservation.md`), and
> the library itself lives on the HDD, so nothing is lost on reboot.

---

## The content server

The server exposes the whole library over HTTP and OPDS. Use it from any
browser on the LAN, or from an OPDS-capable reader app.

### Browsing

```text
http://ayse.local:8080/
```

The web UI mirrors the library metadata: search, sort, cover grid, download
any format in any output. Log in with username `eter` if prompted — Calibre
asks you to set a username/password the first time you open the web UI, and
stores it in `~/.config/calibre/server-users.sqlite` (preserved on
`/persistent`).

### OPDS (for reader apps)

The catalog is available at:

```text
http://ayse.local:8080/opds
```

Add this URL as an "OPDS catalog" in apps like **PocketBook**, **KOReader**
(`http://ayse.local:8080/opds`), or **Lithium** on Android. Apps that speak
OPDS can browse the catalog, download books, and even update book formats.

### Downloading a specific book from the CLI

```bash
curl -o book.epub "http://ayse.local:8080/browse/book/2/download/1/Book.epub"
```

(Book IDs are visible in the URLs / the `metadata.db`.)

---

## Library on the HDD

The library is `~/Biblioteca do calibre → /storage/home/eter/Biblioteca do calibre` on
the Btrfs partition of `/dev/sda`, the same place as `Downloads`/`Music`/
`Videos`. This keeps e-books (which are large-ish and grow over time) off the
SSD and off the tmpfs root.

### Disk usage

```bash
du -sh "/storage/home/eter/Biblioteca do calibre"
df -h /storage
```

### Moving the library

Change `libraryDir` in `mon/sifa/medya/calibre.nix` (and mirror it in
`mon/sifa/servi/calibre.nix`), then `sudo nixos-rebuild switch --flake .`.

> **Caution:** Calibre's internal book folders are hashed by the library
> location. If you *move* an existing library (rather than starting fresh),
> move the whole directory, not individual books, and then re-run the GUI
> once to let Calibre re-verify the library.

---

## Troubleshooting

### The server won't start

```bash
journalctl -u calibre-server -n 30 --no-pager
```

Common causes:

- The library directory is missing — the service needs it to exist. Create
  it (or run the GUI once) and restart:
  ```bash
  sudo -u eter mkdir -p "/storage/home/eter/Biblioteca do calibre"
  sudo systemctl restart calibre-server
  ```
- Wrong ownership — must be `eter:users`, mode `0755`:
  ```bash
  sudo chown eter:users "/storage/home/eter/Biblioteca do calibre"
  ```

### "Connection refused" on port 8080

The service is down or the firewall is closed:

```bash
systemctl status calibre-server
sudo ss -tlnp | grep :8080
sudo iptables -L -n | grep 8080
```

### The GUI asks to create a new library every launch

The symlink is missing, so Calibre's default `~/Biblioteca do calibre` path is
empty and it thinks the library was deleted. Fix:

```bash
sudo systemd-tmpfiles --create
ls -la /home/eter/ | grep Calibre
```

### Web UI asks for a password I don't remember

Calibre stores server users in `~/.config/calibre/server-users.sqlite`.
Delete it (resets all server accounts) and open the web UI again to set a
fresh one:

```bash
rm ~/.config/calibre/server-users.sqlite
sudo systemctl restart calibre-server
```

---

## Service management

The server runs as `calibre-server.service` under user `eter`.

```bash
# Status
systemctl status calibre-server

# Start / stop / restart
sudo systemctl start calibre-server
sudo systemctl stop calibre-server
sudo systemctl restart calibre-server

# Live logs
journalctl -u calibre-server -f

# Last 50 log lines
journalctl -u calibre-server -n 50 --no-pager
```

### Disable the service

```nix
# In mon/mehmangi/ayse/estandar.nix
drevosim.servi.calibre.enable = false;
```

Then `sudo nixos-rebuild switch --flake .`. The library on the HDD and the
desktop app are unaffected.

---

## Security and limits

- **No authentication.** `calibre-server` ships with HTTP basic auth
  (username/password set via the web UI), but by default the module binds to
  `0.0.0.0` with the port open on the LAN. Anyone on the network can reach
  the login page; the credentials are your only gate. Do **not** port-forward
  8080 to the internet.
- **Plain HTTP, no TLS.** Keep it on the LAN / Tailscale. If you need remote
  access, put it behind a reverse proxy with TLS (e.g. Caddy) instead of
  exposing 8080 directly.
- **Runs as `eter`.** The server shares the desktop user's library and
  config. It is not isolated from the user account by design — that keeps the
  single-user setup simple.
- **No upload limits.** Calibre enforces nothing; the HDD is the only bound.
  Watch `df -h /storage`.
- **Only Calibre formats.** The server serves whatever formats you imported
  (`epub`, `azw3`, `mobi`, `pdf`, etc.), converted on the fly where needed.

---

## Quick reference

```bash
# Desktop app
calibre

# Server status / logs
systemctl status calibre-server
journalctl -u calibre-server -n 50

# Web UI / OPDS
http://ayse.local:8080/
http://ayse.local:8080/opds

# Library location
ls -la /home/eter/ | grep Calibre
du -sh "/storage/home/eter/Biblioteca do calibre"
```

If something doesn't work, check `journalctl -u calibre-server -n 50` first.
