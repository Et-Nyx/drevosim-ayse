# AdGuard Home (Tailnet DNS Adblocker) — Operator's Manual

A practical guide to the DNS-level adblocker running on `ayse`. Read this
when ads reappear on tailnet devices, when you need to allowlist a domain,
or when the tailnet's DNS seems broken.

The service is [AdGuard Home](https://github.com/AdguardTeam/AdGuardHome),
listening on `127.0.0.1:53` and the Tailscale IP (`100.75.243.95:53`), with
the dashboard exposed over the tailnet at
`https://ayse.tailfcc763.ts.net:3000`.

---

## Table of contents

- [What it is and what it isn't](#what-it-is-and-what-it-isnt)
- [How it works](#how-it-works)
- [Configuration options](#configuration-options)
- [Quick start](#quick-start)
- [Dashboard](#dashboard)
- [Common tasks](#common-tasks)
- [Troubleshooting](#troubleshooting)
- [Service management](#service-management)
- [Security and limits](#security-and-limits)
- [Quick reference](#quick-reference)

---

## What it is and what it isn't

| This is | This is not |
|---------|-------------|
| DNS-level blocking: ad/tracking domains resolve to `0.0.0.0` for every device that uses the tailnet's DNS | A VPN-level or firewall-level blocker — devices that bypass the tailnet DNS (Private DNS, DoH in-browser) are not filtered |
| A single global nameserver for the whole tailnet, set in the Tailscale admin console | A local-LAN DNS server — port 53 is only open on the `tailscale0` interface |
| One source of truth for "who asked for what" (query log, per-client stats) | A caching-optimized resolver — it adds a small amount of latency, not removes it |
| Configurable through the dashboard after a declarative bootstrap | Fully declarative — the YAML is mutable by design (see [State](#state-and-persistence)) |

---

## How it works

```
┌────────────┐  tailnet   ┌──────────────────────────────┐   DoH   ┌────────────┐
│ Any device │───────────>│ ayse                          │────────>│ Cloudflare │
│ (phone,    │  UDP/TCP   │ AdGuard Home                  │  HTTPS  │ Google DNS │
│ laptop…)   │  :53       │  ├─ filter lists (2 seeded)   │         │ (upstream) │
└────────────┘            │  └─ query log / per-client    │         └────────────┘
                          └──────────────────────────────┘
┌────────────┐  127.0.0.1 ┌──────────────────────────────┐
│ Browser on │───────────>│ tailscaled stub               │
│ ayse       │  100.100.  │ 100.100.100.100:53            │
│ (resolved  │  100.100)  │  └─ global nameserver = ayse  │
│ via NM)    │            │    = itself (no loop:         │
└────────────┘            │    upstreams are public DoH)  │
                          └──────────────────────────────┘
```

- **The tailnet points at `ayse`.** In the Tailscale admin console, the
  global nameserver is `100.75.243.95` with *Override local DNS* enabled.
  Every tailnet device sends its DNS there — no per-device configuration.
- **The host filters itself for free.** `ayse`'s own resolver path is
  `/etc/resolv.conf` → `100.100.100.100` (tailscaled's MagicDNS stub) →
  global nameserver (`ayse`) → AdGuard Home.
- **Binding is deliberately narrow.** AdGuard Home binds `127.0.0.1:53` +
  the Tailscale IP only — **not** `0.0.0.0`, because tailscaled already
  binds `100.100.100.100:53` and a wildcard bind would collide with it.
- **No resolver loop.** Upstreams are public DoH (Cloudflare, Google) with
  plain-DNS bootstrap servers. Never add `100.100.100.100` as an upstream:
  the stub forwards to the global nameserver (this very service) and the
  query would chase its own tail.
- **MagicDNS still works.** Tailnet clients resolve `*.ts.net` names
  locally through the tailscaled stub; only non-MagicDNS queries reach
  AdGuard Home. Reverse lookups for `100.x` addresses are likewise handled
  by MagicDNS.

---

## Configuration options

All under `drevosim.servi.adguard` (module: `mon/sifa/servi/adguard.nix`):

| Option | Default | Meaning |
|--------|---------|---------|
| `enable` | `false` | Set `true` in `mon/mehmangi/ayse/estandar.nix` |
| `tailscaleIp` | `"100.75.243.95"` | Tailscale IPv4 to bind DNS on; the admin-console nameserver must match |
| `webPort` | `3000` | Dashboard port (loopback only; proxied by Tailscale Serve) |
| `upstreams` | Cloudflare + Google DoH | Upstream resolvers, queried in parallel (`all_servers`) |
| `bootstrapDns` | `1.1.1.1`, `8.8.8.8`, `9.9.9.9` | Plain DNS used only to resolve the DoH upstream hostnames |

The module also merges its own entries into the tailscale module:
port `webPort` on the `tailscale0` firewall and a Serve route for the
dashboard (`attrsOf`/`listOf` options merge across modules — this is why
`mon/sifa/servi/tailscale.nix` keeps its defaults in `config`, not in the
option defaults).

---

## Quick start

1. Rebuild: `sudo nixos-rebuild switch --flake .` — AdGuard Home starts and
   binds loopback + Tailscale IP.
2. In the **Tailscale admin console** → *DNS*:
   - *Nameservers* → *Add nameserver* → *Custom* → `100.75.243.95`
   - Enable **Override local DNS**
3. Verify from the node: `dig @127.0.0.1 doubleclick.net` → `0.0.0.0`.
4. Verify from a phone (Wi-Fi or LTE, Tailscale on): ads vanish; the
   dashboard shows the phone as a client.

Until step 2 is done, nothing changes for anyone — the rebuild alone is
safe.

---

## Dashboard

Reachable only over the tailnet:

```
https://ayse.tailfcc763.ts.net:3000
```

(Served through `tailscale serve` with a Tailscale-issued certificate; the
backend is `127.0.0.1:3000` and is never exposed by the firewall.)

**First visit:** the seeded YAML has no dashboard user, so AdGuard Home
shows its first-run page — create the admin login there. The rest of the
configuration is kept.

What lives where in the dashboard:

- **Filters** — the two seeded lists (AdGuard DNS filter, OISD Small) plus
  anything you add. Add lists here, not in Nix.
- **Query log** — every lookup, per client. Blocked entries show `0.0.0.0`.
- **Client settings** — per-device rules (e.g. pause filtering for a
  specific laptop) work because each device's Tailscale IP is visible.

---

## Common tasks

**Allowlist a domain a filter wrongly blocks:** dashboard → *Filters* →
*Custom filtering rules*: `@@||example.com^$dnstype` style entries; or
use the query log's right-click shortcuts.

**Pause blocking everywhere:** dashboard → *Settings* → *General
settings* → toggle *Protection*. There's also a temporary pause button on
the dashboard card.

**Add a blocklist:** dashboard → *Filters* → *DNS blocklists* → *Add
blocklist*. No rebuild needed.

**Use a different upstream (e.g. unfiltered DoH):** dashboard →
*Settings* → *DNS settings* → *Upstream DNS servers*. Keep the "don't use
`100.100.100.100`" rule in mind.

**Temporarily point one device away from the blocker:** on that device,
disable *Use Tailscale DNS* (`tailscale set --accept-dns=false` on
desktops; toggle in the OS VPN settings on mobile). It falls back to its
local DHCP DNS.

---

## Troubleshooting

**No DNS anywhere in the tailnet (sites don't resolve on the phone):**
- Is `ayse` awake? If the laptop is off/asleep, tailnet devices keep
  failing DNS until they drop off the tailnet and fall back to local DNS.
  Check: `tailscale status` from any device.
- `systemctl status adguardhome` on `ayse`.
- Did the node's Tailscale IP change? (`tailscale ip -4`) — if it is no
  longer `100.75.243.95`, update `drevosim.servi.adguard.tailscaleIp`,
  rebuild, and update the nameserver entry in the admin console.

**Blocked domain needed right now:** dashboard → custom filtering rules
(`@@||domain^`), or pause protection from the dashboard card.

**Ads still visible on one device:** that device is bypassing the tailnet
DNS. Usual suspects:
- Android **Private DNS** set to a DoT hostname — set it to *Automatic*.
- iOS **iCloud Private Relay** — exempt Tailscale or disable Relay.
- Browser-internal DoH (Firefox/Chrome secure DNS) — turn it off or set
  it to use the OS resolver.

**`dig @127.0.0.1 example.com` times out on the node:** AdGuard Home is
down or still starting (`Restart=always` retries every 10 s).

**Dashboard unreachable:** the Serve route must exist — check
`tailscale serve status` shows `3000 → 127.0.0.1:3000`; the
`tailscale-serve` service reapplies routes on boot.

---

## Service management

```bash
systemctl status adguardhome          # running?
journalctl -u adguardhome -f          # live logs
sudo systemctl restart adguardhome    # restart
sudo systemctl stop adguardhome       # stop (tailnet DNS goes with it)
```

The unit runs as a systemd **DynamicUser** with the state directory at
`/var/lib/AdGuardHome`.

### State and persistence

- Everything mutable lives in `/var/lib/AdGuardHome/AdGuardHome.yaml` —
  the root filesystem is persistent, so it survives reboots.
- `mutableSettings = true` (the default): on start, the Nix-side
  `services.adguardhome.settings` are merged into the file, but values
  already present from the dashboard win. Consequence: **after the first
  run, the dashboard is the source of truth** for most settings; changing
  Nix-side values only affects keys the UI has never written.
- To reset to the declarative bootstrap: stop the service, delete (or
  back up) `/var/lib/AdGuardHome/AdGuardHome.yaml`, start again.

---

## Security and limits

- Port 53 is reachable **only via `tailscale0`** — LAN and internet
  devices cannot use (or attack) the resolver. The dashboard is loopback
  only and additionally gated by tailnet identity + Tailscale TLS.
- The resolver is open to your tailnet only; still, anyone in your
  tailnet (shared nodes, etc.) can query it.
- DoH upstreams keep outbound queries encrypted; the tailnet leg is
  encrypted by WireGuard regardless.
- DNS is the single point of failure for tailnet devices (Override local
  DNS). If `ayse` sleeps or dies, DNS breaks until devices fall back.
  For 24/7 filtering, keep the laptop awake; otherwise accept the
  fallback gap.

---

## Quick reference

| What | Where / command |
|------|-----------------|
| Dashboard | `https://ayse.tailfcc763.ts.net:3000` |
| DNS endpoint (tailnet) | `100.75.243.95:53` (UDP+TCP) |
| Global nameserver | Tailscale admin console → DNS → `100.75.243.95` + Override local DNS |
| Test blocking | `dig @100.75.243.95 doubleclick.net` → `0.0.0.0` |
| Test passthrough | `dig @100.75.243.95 example.com` → real answer |
| Config file | `/var/lib/AdGuardHome/AdGuardHome.yaml` |
| Module | `mon/sifa/servi/adguard.nix` |
| Enabled at | `mon/mehmangi/ayse/estandar.nix` (`drevosim.servi.adguard.enable = true`) |
| Logs | `journalctl -u adguardhome` |
