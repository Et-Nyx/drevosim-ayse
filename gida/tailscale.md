# Tailscale — Operator's Manual

A practical guide to the [Tailscale](https://tailscale.com/) mesh VPN on
`ayse`. Read this when you need to reach your home services from your
phone or laptop, debug the tailnet, or change which services are exposed.

Tailscale gives `ayse` a stable mesh address reachable from any of your
devices. The web services (SillyTavern, Kokoro) are exposed over the
tailnet through **Tailscale Serve**, which fronts them with valid HTTPS
certificates on the node's MagicDNS name.

---

## Table of contents

- [What it is](#what-it-is)
- [How it works](#how-it-works)
- [Configuration options](#configuration-options)
- [Quick start](#quick-start)
- [Access from your phone](#access-from-your-phone)
- [The auth key (agenix)](#the-auth-key-agenix)
- [State and persistence](#state-and-persistence)
- [Managing serve routes](#managing-serve-routes)
- [Grayjay sync over the tailnet](#grayjay-sync-over-the-tailnet)
- [Troubleshooting](#troubleshooting)
- [Service management](#service-management)
- [Uninstall / disable](#uninstall--disable)

---

## What it is

- **Tailscale** — a WireGuard-based mesh VPN. Each node gets a stable
  `100.x.y.z` address in your tailnet (`tailfcc763.ts.net`) that works
  from anywhere, without port-forwarding or public IPs.
- **MagicDNS** — `ayse.tailfcc763.ts.net` resolves to `ayse`'s tailnet
  address on every node in the tailnet.
- **Tailscale Serve** — proxies a local service to an HTTPS URL on the
  MagicDNS name, with a certificate issued by Tailscale's CA. No Caddy,
  no manual cert renewal.
- Two services are currently exposed:
  - `https://ayse.tailfcc763.ts.net:8000` → SillyTavern
  - `https://ayse.tailfcc763.ts.net:8880` → Kokoro TTS API
- Because of Serve, the backend services now bind **only to loopback**
  (`127.0.0.1`). The only way to reach them from outside the machine is
  through the tailnet HTTPS proxy — there is no plain-HTTP or LAN path
  anymore.

---

## How it works

```
┌──────────────┐   WireGuard   ┌───────────────────────────┐   local    ┌────────────────┐
│ Phone        │──────────────>│ ayse (tailscaled)         │──────────>│ SillyTavern    │
│ galaxy-s24-fe│  100.107.x.y  │  ├─ tailscale0 (100.75.x) │ 127.0.0.1  │ 127.0.0.1:8000 │
└──────────────┘               │  └─ serve (HTTPS :8000,   │            └────────────────┘
                               │                :8880)     │ 127.0.0.1  ┌────────────────┐
└──────────────┐               │                            │──────────>│ Kokoro TTS     │
│ Laptop       │──────────────>│                            │            │ 127.0.0.1:8880 │
└──────────────┘   WireGuard   └───────────────────────────┘            └────────────────┘
```

- `tailscaled` opens the tunnel and creates `tailscale0`.
- MagicDNS resolves `ayse.tailfcc763.ts.net` to `100.75.243.95`
  (IPv4) and `fd7a:115c:a1e0::534:f360` (IPv6).
- **Serve** binds the tailnet addresses on ports `8000`/`8880`,
  terminates TLS, and proxies to the loopback backends.
- The firewall (`nftables`) allows `8000`/`8880` **only** on the
  `tailscale0` interface, plus `41641/udp` for direct peer connections.
- Node identity (`tailscaled.state`) lives in `/var/lib/tailscale`,
  preserved on `/persistent`.

### Why the backends are on loopback now

SillyTavern and Kokoro originally bound `0.0.0.0`. That clashed with
Serve, which could not bind the tailnet IPv4 address (`bind: address
already in use`) and silently fell back to IPv6-only — unreliable from
phones. Binding the backends to `127.0.0.1` lets Serve own the tailnet
addresses. This matches the old Caddy setup, where services also sat on
localhost behind a TLS proxy.

---

## Configuration options

All options live under `drevosim.servi.tailscale.*`. Defaults:

| Option | Default | Description |
|--------|---------|-------------|
| `enable` | `true` | Master switch. |
| `authKeyFile` | `config.age.secrets.ayse-tailscale-auth.path` | File with the auth key used to register the node. |
| `ports` | `[ 8000 8880 12315 ]` | TCP ports opened on the `tailscale0` interface only. `12315` is the Grayjay sync listener. |
| `serve` | `{ "8000" = "127.0.0.1:8000"; "8880" = "127.0.0.1:8880"; }` | Serve routes: HTTPS port on the MagicDNS name → local backend. `{}` disables Serve. |

To change routes, edit `mon/sifa/servi/tailscale.nix`:

```nix
drevosim.servi.tailscale = {
  enable = true;
  serve = {
    "8000" = "127.0.0.1:8000";  # SillyTavern
    "8880" = "127.0.0.1:8880";  # Kokoro
    # "9000" = "127.0.0.1:9000"; # example: add another
  };
};
```

Then:

```bash
sudo nixos-rebuild switch --flake .#ayse
```

> **Note:** the flake only includes **git-tracked** files. After editing
> any module or `.age` file, `git add` it first, otherwise the rebuild
> silently uses a source tree without your change.

---

## Quick start

1. Check the node is registered:

   ```bash
   sudo tailscale status
   ```

   ```
   100.75.243.95   ayse           Et-Nyx@  linux    -
   100.107.193.67  galaxy-s24-fe  Et-Nyx@  android  -
   ```

2. Confirm the serve routes:

   ```bash
   sudo tailscale serve status
   ```

   ```
   https://ayse.tailfcc763.ts.net:8000 (tailnet only)
   |-- / proxy http://127.0.0.1:8000

   https://ayse.tailfcc763.ts.net:8880 (tailnet only)
   |-- / proxy http://127.0.0.1:8880
   ```

3. Test HTTPS locally (a valid Tailscale cert, no `-k`):

   ```bash
   curl -I https://ayse.tailfcc763.ts.net:8000
   curl https://ayse.tailfcc763.ts.net:8880/health
   ```

   You should see `HTTP/2 200` and `{"status":"healthy"}`.

4. Ping the phone from the node:

   ```bash
   sudo tailscale ping galaxy-s24-fe
   ```

---

## Access from your phone

1. Install the **Tailscale** app and sign in with the same account
   (Et-Nyx@).
2. MagicDNS will resolve `ayse.tailfcc763.ts.net` once you're on the
   tailnet.
3. Open in the browser:

   - **SillyTavern**: `https://ayse.tailfcc763.ts.net:8000`
   - **Kokoro dashboard**: `https://ayse.tailfcc763.ts.net:8880/dashboard`

The lock icon is valid (Tailscale-issued cert). Traffic travels
encrypted by WireGuard end-to-end, including over mobile data.

> Access control inside the tailnet is governed by Tailscale ACLs
> (default: your nodes can talk to each other). To restrict which
> devices can reach `ayse`, edit the ACL policy in the admin console
> (https://login.tailscale.com/admin/acls).

---

## The auth key (agenix)

`ayse` registers automatically on first boot using an auth key stored
as an [agenix](https://github.com/ryantm/agenix) secret:

- Encrypted file: `siri/ayse-tailscale-auth.age`
- Decrypted at activation to `services.tailscale.authKeyFile`
- CLI rules: `siri/secrets.nix` (adds the secret to the recipient list)

To regenerate (e.g. after a full reinstall):

1. Create an auth key in the admin console:
   https://login.tailscale.com/admin/settings/keys
2. Encrypt it into the repo (run from the repo root):

   ```bash
   EDITOR="<editor>" nix run 'github:ryantm/agenix' -- \
     -e siri/ayse-tailscale-auth.age \
     -r 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOsp4531DnJUhaPOQ3OingU54i0JpUPXI5AI9FK2B/MH root@ayse'
   ```

3. `git add siri/ayse-tailscale-auth.age` then
   `sudo nixos-rebuild switch --flake .#ayse`.

> **Gotcha:** use the native `ssh-ed25519 <pubkey>` recipient string (as
> in `siri/secrets.nix`), **not** the `ssh-to-age` X25519 form. On the
> current toolchain, `ssh-to-age` recipients can't be decrypted by
> `age -i` with the host key — `ayse`'s existing secrets all use the
> native `ssh-ed25519` form.

---

## State and persistence

`/var/lib/tailscale` is preserved on `/persistent` via the
`preservation` module, so:

- the node identity (`tailscaled.state`) survives reboots and rebuilds —
  the node keeps its name `ayse` and address `100.75.243.95`;
- the **serve config** persists too, so HTTPS routes survive reboots
  even if the oneshot service hasn't re-run yet;
- the single-use auth key is only consumed once — after that the node
  re-authenticates with its stored identity.

---

## Managing serve routes

Routes are declared in `drevosim.servi.tailscale.serve` and applied on
boot by the `tailscale-serve.service` oneshot.

```bash
# View current routes
sudo tailscale serve status

# Remove ALL routes (also disables the HTTPS proxy)
sudo tailscale serve reset
```

Because the backends bind loopback, removing a serve route makes the
service **unreachable from the tailnet** (it's still reachable on
`127.0.0.1` locally). To permanently drop a route, edit the `serve`
option and rebuild.

> `tailscale serve status` needs the port open on `tailscale0`. If you
> add a route for a new port, also add it to `drevosim.servi.tailscale.ports`.

---

## Grayjay sync over the tailnet

Grayjay Desktop and the Android client sync over a Noise-protocol TCP
channel. The desktop's sync listener is **port `12315`**, bound to
`0.0.0.0` whenever Grayjay is running with synchronization enabled
(our wrapper seeds `settings.json` with it on). Port `12315` is opened
on `tailscale0` by the `drevosim.servi.tailscale.ports` option.

### How discovery works (and why the tailnet needs manual pairing)

- On the same Wi-Fi, devices find each other via **mDNS**
  (`_gsync._tcp.local`) and pair by scanning the QR code.
- **mDNS is link-local** — it does not cross the tailnet to a phone on
  cellular. Over Tailscale you pair manually using the pairing link,
  which already contains the node's tailnet address.

### Manual pairing over Tailscale

1. Launch Grayjay on `ayse` (the wrapper re-seeds sync settings on
   every start). Confirm the listener is up:

   ```bash
   ss -tln | grep 12315        # 0.0.0.0:12315 → sync listener
   ```

2. In the desktop app: **Settings → Synchronization → Pairing link**
   (or `curl http://127.0.0.1:<grayjay-port>/sync/pairing` to fetch the
   `grayjay://sync/...` URL).

3. On the phone (on the tailnet): **Grayjay → Sync → Pair**, then scan
   the QR or paste the link. The link's embedded addresses include
   `100.75.243.95:12315`, so the tailnet path is used directly.

4. Approve the **device authorization** prompt on the desktop.

5. Once authorized, subscriptions, subscription groups, playlists,
   watch-later, and history sync between the two devices. The desktop
   keeps reconnecting via "Connect Last Known" + relay, so sync stays
   alive without re-pairing.

### Notes

- If the phone's direct connect lands on a LAN address first, the
  relay fallback (enabled in the seed) completes the pairing.
- mDNS auto-discovery over the tailnet is **not** supported; always
  pair via the link.
- Sync requires the **desktop Grayjay to be running** — it is a GUI
  app, not a daemon. Launch it when you want to sync.

---

## Troubleshooting

### "TLS connect error: wrong version number" when testing on ayse

You hit the raw loopback service, not the Serve proxy. Connect through
the MagicDNS name (or the `100.75.243.95` address) rather than
`127.0.0.1` when testing HTTPS:

```bash
curl -I https://ayse.tailfcc763.ts.net:8000   # right
curl -I http://127.0.0.1:8000                 # plain HTTP, not Serve
```

### Serve bound to IPv6 only / "bind: address already in use"

A backend is holding the port on `0.0.0.0`, so Serve can't bind the
tailnet IPv4 address. This is why the backends must stay on
`127.0.0.1`:

```bash
ss -tln | grep -E ':8000|:8880'
```

`100.75.243.95:8000` should be the Serve listener and `127.0.0.1:8000`
the backend. If you see `0.0.0.0:8000`, a service is binding globally —
fix its `host`/listen address.

### `tailscale-serve.service` fails with "invalid argument format"

The `--yes` flag must come **before** the target (Go's flag parser
stops at the first positional argument). The module generates
`tailscale serve --bg --yes --https=<port> <backend>`; if you edit the
script by hand, keep that order.

### Node didn't auto-register

Check the auth key was decrypted:

```bash
ls -la /run/agenix/ayse-tailscale-auth
sudo cat /run/agenix/ayse-tailscale-auth
```

If it's missing or empty, agenix didn't decrypt it — check
`siri/secrets.nix` has the correct recipient. If the key expired or was
already consumed, generate a new one (see [The auth key](#the-auth-key-agenix)).

### Phone can't reach the node

- Both devices must be on the same tailnet and logged into the same
  account.
- `sudo tailscale ping <device>` from ayse — if it hangs, the direct
  path isn't up; check `sudo tailscale status` for both nodes showing
  online.
- ACLs in the admin console must allow the devices to talk.

### Services stopped working after a rebuild

Make sure all edited files were `git add`-ed before `nixos-rebuild`
(untracked files are excluded from the flake source).

---

## Service management

```bash
# Tailscale daemon
systemctl status tailscaled
sudo systemctl restart tailscaled

# Serve routes (oneshot)
systemctl status tailscale-serve
sudo systemctl restart tailscale-serve

# Node status / IP
sudo tailscale status
tailscale ip -4

# Live tailscaled logs
journalctl -u tailscaled -f

# Last 50 log lines
journalctl -u tailscaled -n 50 --no-pager
```

`tailscale-serve.service` runs after `tailscaled.service` and is
idempotent — re-running it just re-applies the same routes.

---

## Uninstall / disable

```nix
# In mon/mehmangi/ayse/estandar.nix (or via module default)
drevosim.servi.tailscale.enable = false;
```

Then `sudo nixos-rebuild switch --flake .#ayse`. `tailscaled` and the
serve routes are removed. To also leave the tailnet permanently:

```bash
sudo tailscale logout
```

The `/var/lib/tailscale` state stays on `/persistent`; delete it only
if you plan to re-register from scratch (you'll need a fresh auth key).

---

## Quick reference

```bash
# Status
sudo tailscale status

# My IPs
tailscale ip -4; tailscale ip -6

# Serve routes
sudo tailscale serve status

# Test HTTPS
curl -I https://ayse.tailfcc763.ts.net:8000
curl https://ayse.tailfcc763.ts.net:8880/health

# From the phone
#   https://ayse.tailfcc763.ts.net:8000   (SillyTavern)
#   https://ayse.tailfcc763.ts.net:8880/dashboard  (Kokoro)

# Grayjay sync (desktop must be running)
ss -tln | grep 12315

# Logs
journalctl -u tailscaled -f
```

If something doesn't work, check `journalctl -u tailscaled -n 50`
first.
