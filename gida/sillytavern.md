# SillyTavern — Operator's Manual

A practical guide to the [SillyTavern](https://sillytavern.app/) web UI
running on `ayse`. Read this when you need to configure characters,
extensions, the chat backend, or the bundled TTS integration.

The web UI is at `http://<ayse-ip>:8000` and is pre-configured to talk
to the local Kokoro TTS service and the OpenCode Go chat relay.

---

## Table of contents

- [What it is](#what-it-is)
- [How it works](#how-it-works)
- [Configuration options](#configuration-options)
- [Quick start](#quick-start)
- [Pre-configured integrations](#pre-configured-integrations)
- [Bundled extensions](#bundled-extensions)
- [Whitelist and access control](#whitelist-and-access-control)
- [State and persistence](#state-and-persistence)
- [Updating extensions](#updating-extensions)
- [Troubleshooting](#troubleshooting)
- [Service management](#service-management)
- [Disable / reset](#disable--reset)

---

## What it is

- [SillyTavern](https://sillytavern.app/) — a feature-rich front-end
  for LLM chats, with a focus on roleplay and character cards.
- Running on `0.0.0.0:8000`, accessible from LAN and Tailscale.
- **Whitelist mode** is on by default. Only the listed IPs can
  connect (see [Whitelist and access control](#whitelist-and-access-control)).
- **Password login** is on by default via SillyTavern's multi-user
  mode (see [User accounts](#user-accounts-multi-user-login)).
- **TTS** is pre-configured to use the local Kokoro service
  (`http://127.0.0.1:8880/v1`) with the `af_heart` voice.
- **Chat backend** is pre-configured to use the OpenCode Go relay via
  Cloudflare Worker; the access token is decrypted from
  `siri/ayse-go-relay.age` and the fallback model is `deepseek-v4-flash`.
- **Multi-user login** is enabled: password-protected sessions with a
  discreet login page. The admin account is `exdunyayen`; its password
  comes from `siri/ayse-sillytavern.age`
  (see [User accounts](#user-accounts-multi-user-login)).
- Eight third-party extensions are bundled declaratively from flake
  inputs (see [Bundled extensions](#bundled-extensions)).
- FlareSolverr is started automatically when CharacterLibrary plugins
  are enabled, for Cloudflare bypass.

---

## How it works

```
┌──────────────┐   HTTP/8000  ┌──────────────────┐    HTTPS    ┌──────────────┐
│   Browser    │<────────────>│ SillyTavern      │<──────────>│ OpenCode Go  │
│ (you, on     │              │ (Node.js)        │            │ relay worker │
│  LAN/Tail-   │              │  + extensions    │            └──────────────┘
│  scale)      │              │  + seeder        │    HTTP    ┌──────────────┐
│              │              │                  │<──────────>│ Kokoro TTS   │
│              │              │                  │            │ (8880)       │
└──────────────┘              └──────────┬────────┘            └──────────────┘
                                        │
                                        ▼
                                /var/lib/SillyTavern
                                (preserved on /persistent)
```

- SillyTavern is a Node.js application. The NixOS module installs the
  upstream `services.sillytavern` service and configures it.
- The seeder script (`sillytavern-seed-state`) runs before the service
  starts and:
  - bootstraps `config.local.yaml` from the package default on first
    run,
  - patches declarative settings: `listen=true`, `listenAddress.ipv4=
    0.0.0.0`, `whitelistMode=true`, `whitelist=[...]`, `extensions.*`
    flags,
  - seeds the admin user's (`data/$adminHandle/`) `settings.json`
    with TTS + LLM relay configuration,
  - writes the relay access token to the admin user's
    `secrets.json`,
  - seeds the admin account password from the agenix secret (via
    ST's `recover.js`).
- The third-party extensions are symlinked into
  `/var/lib/SillyTavern/extensions/` by `systemd.tmpfiles` rules.
- State is preserved on `/persistent` via the `preservation` module.

### Why `config.local.yaml` and not CLI flags

The upstream NixOS module passes listen / whitelist settings as CLI
flags like `--listen=1`. SillyTavern's yargs parser misinterprets
`--listen=1` (treats it as `--listen 1`, breaking the argument). We
sidestep this by seeding `config.local.yaml` declaratively instead.

---

## Configuration options

All options live under `drevosim.servi.sillytavern.*`. Defaults:

| Option | Default | Description |
|--------|---------|-------------|
| `enable` | `false` | Master switch. Set to `true` in `estandar.nix` to enable. |
| `port` | `8000` | Bind port. |
| `host` | `0.0.0.0` | Bind address. |
| `openFirewall` | `true` | Open the port in the firewall. |
| `ttsApiUrl` | `http://127.0.0.1:8880/v1` | OpenAI-compatible TTS API URL. |
| `defaultVoice` | `af_heart` | Default TTS voice seeded into settings. |
| `llmRelayUrl` | `https://go-relay.eter-nyx-635.workers.dev/v1` | Chat relay URL. |
| `llmRelayKeyFile` | `config.age.secrets.ayse-go-relay.path` | Path to a file containing the relay access token. |
| `llmDefaultModel` | `deepseek-v4-flash` | Fallback model seeded before the relay is queried. |
| `enableUserAccounts` | `true` | Multi-user mode with password-protected sessions. |
| `enableDiscreetLogin` | `true` | Login form only (no user list on the login page). |
| `sessionTimeout` | `-1` | Session timeout in seconds (`-1` = no expiry, `0` = browser close). |
| `adminHandle` | `default-user` | Admin account handle. Set to `exdunyayen` in `estandar.nix`. |
| `adminPasswordFile` | `config.age.secrets.ayse-sillytavern.path` | Plaintext admin password, re-applied on every service start. |
| `enableCharacterLibraryPlugins` | `true` | Enable `cl-helper` server plugin and FlareSolverr. |
| `extensions` | eight curated entries | Extensions to symlink into the global extensions directory. |

To change, edit `mon/mehmangi/ayse/estandar.nix`:

```nix
drevosim.servi.sillytavern = {
  enable = true;
  defaultVoice = "pf_dora";   # use the Portuguese voice by default
  llmDefaultModel = "deepseek-v4-flash";
};
```

Then `sudo nixos-rebuild switch --flake .`.

---

## Quick start

1. Make sure the TTS service is running (see `gida/kokoro.md`):

   ```bash
   systemctl status kokoro-tts
   ```

2. Confirm SillyTavern is running:

   ```bash
   systemctl status sillytavern
   ```

   You should see `Active: active (running)`. The first start may take
   a few seconds while the seeder runs and dependencies are installed.

3. Open the UI:

   ```
   http://<ayse-ip>:8000
   ```

4. Log in on the login page with the admin account `exdunyayen` and
   the password stored in `siri/ayse-sillytavern.age`. On first visit,
   the UI may prompt for a one-time API key. Click through the welcome
   screens — your relay credentials are already pre-seeded in
   `data/exdunyayen/secrets.json` and `data/exdunyayen/settings.json`.

5. Pick a character, send a message, and verify the response streams
   in. The relay auto-discovers available models via
   `/v1/models`; you can pick from the list or stick with
   `deepseek-v4-flash`.

---

## Pre-configured integrations

### TTS (Kokoro)

The seeder configures SillyTavern's TTS extension with:

- **Provider**: OpenAI Compatible
- **URL**: `http://127.0.0.1:8880/v1` (Kokoro)
- **Model**: `kokoro`
- **Default voice**: `af_heart`
- **Available voices**: 24 curated English voices (full list is
  available — the seeder only seeds the most common ones; you can
  edit the list in the TTS extension UI).

The 24 seeded voices are:

```text
af_heart, af_alloy, af_aoede, af_bella, af_jadzia, af_jessica,
af_kore, af_nicole, af_nova, af_river, af_sarah, af_sky,
am_adam, am_echo, am_eric, am_fenrir, am_liam, am_michael,
am_onyx, am_puck, bf_emma, bf_isabella, bm_daniel, bm_george
```

All 67 voices are available — add the missing ones in the TTS
extension's "Available voices" field.

### Chat backend (OpenCode Go relay)

The seeder configures SillyTavern's Custom chat provider with:

- **URL**: `https://go-relay.eter-nyx-635.workers.dev/v1`
- **Model**: `deepseek-v4-flash` (fallback)
- **API key**: read from `siri/ayse-go-relay.age` (decrypted by
  agenix at boot)

The relay is a Cloudflare Worker that proxies to OpenCode Go and
exposes `/v1/models` so SillyTavern can auto-discover the available
models. Once you've connected once, you can pick from the full model
list — the fallback `deepseek-v4-flash` is just what gets seeded before the
first `/v1/models` fetch completes.

### User accounts (multi-user login)

SillyTavern's built-in multi-user mode is enabled
(`enableUserAccounts = true`):

- **Admin account**: handle `exdunyayen` (`adminHandle`), name
  "Eter". Its data lives in `data/exdunyayen/`.
- **Password**: stored as plaintext in the agenix secret
  `siri/ayse-sillytavern.age` and re-applied to the account on every
  service start via ST's `recover.js` (so the Nix config is the
  source of truth). Note the stored password *hash* in
  `data/_storage/` changes on every boot — that's just a fresh salt;
  the password itself stays the same.
- **Login page**: discreet (`enableDiscreetLogin = true`) — asks for
  username + password, no user list.
- **Sessions**: no expiry by default (`sessionTimeout = -1`).
- **Additional users**: create and manage them in SillyTavern's
  admin panel (User Accounts) after logging in as the admin. Their
  data lives in `data/<handle>/`; their account records in
  `data/_storage/` (keyed by `sha256("user:<handle>")`).

To change the admin password:

```bash
nix run github:ryantm/agenix -- -e siri/ayse-sillytavern.age
sudo nixos-rebuild switch --flake .   # seeder applies it on restart
```

### API call log (in Kokoro dashboard)

Every TTS request that SillyTavern sends to Kokoro shows up in the
Kokoro dashboard's "API call log" panel with the caller identified
as "SillyTavern" (detected via the `User-Agent` header). Useful for
debugging when characters go quiet.

---

## Bundled extensions

Eight third-party extensions are declared as flake inputs and
symlinked into `/var/lib/SillyTavern/extensions/`:

| Extension | Source |
|-----------|--------|
| SillyTavern-CharacterLibrary | `github:Sillyanonymous/SillyTavern-CharacterLibrary` (patched to always use the cl-helper proxy) |
| Extension-TopInfoBar | `github:SillyTavern/Extension-TopInfoBar` |
| Extension-QuickPersona | `github:SillyTavern/Extension-QuickPersona` |
| Extension-PromptInspector | `github:SillyTavern/Extension-PromptInspector` |
| Extension-TypingIndicator | `github:SillyTavern/Extension-TypingIndicator` |
| Extension-Notebook | `github:SillyTavern/Extension-Notebook` |
| Extension-Objective | `github:SillyTavern/Extension-Objective` |
| Ultimate-ChatAssistant | `github:BobTheBinChicken/Ultimate-ChatAssistant` |

The CharacterLibrary extension also gets its `cl-helper` server
plugin symlinked into `/var/lib/SillyTavern/plugins/cl-helper`, which
SillyTavern bind-mounts into the service at startup.

### What CharacterLibrary's cl-helper does

`cl-helper` is a small proxy bundled with CharacterLibrary that
mediates between SillyTavern and the CharaVerse (formerly
Character Tavern) gallery API. The patch applied at build time
(`substituteInPlace modules/providers/chartavern/chartavern-api.js`)
forces the extension to always use the proxy when available, so
image-heavy character cards render reliably.

### FlareSolverr

When `enableCharacterLibraryPlugins = true`, the module enables
`services.flaresolverr`. FlareSolverr is a small Python/Node proxy
that solves Cloudflare anti-bot challenges transparently, used by
CharacterLibrary to fetch character cards from sources protected by
Cloudflare.

---

## Whitelist and access control

Whitelist mode is on by default. The seeder configures:

```yaml
whitelistMode: true
whitelist:
  - 127.0.0.1     # localhost IPv4
  - ::1           # localhost IPv6
  - 100.64.0.0/10 # Tailscale CGNAT range
```

So you can connect from:

- The ayse machine itself.
- Any Tailscale peer (when Tailscale is configured).
- LAN clients that route through Tailscale, or whose IP you add to
  the whitelist.

### Why whitelist mode

SillyTavern refuses to run unauthenticated on non-localhost without
whitelist mode — anyone reaching the port would be able to talk to
the LLM. Whitelist mode with the Tailscale range is the simplest
secure default.

### Adding more IPs

Edit the whitelist in `mon/sifa/servi/ai-chat/sillytavern.nix`:

```nix
${pkgs.yq-go}/bin/yq -i '.whitelist = ["127.0.0.1", "::1", "100.64.0.0/10", "192.168.1.0/24"]' "$CFG_FILE"
```

Then `sudo nixos-rebuild switch --flake .`. The seeder will rewrite
the whitelist on the next start.

---

## State and persistence

`/var/lib/SillyTavern` is preserved on `/persistent`. The important
subdirectories:

- `config.local.yaml` — declarative config (listen, whitelist,
  extensions flags). Seeded by the seeder on first run; do not edit
  by hand (the seeder will overwrite).
- `data/exdunyayen/settings.json` — per-user TTS, LLM, and
  extension settings for the admin account. Seeded on first run; can
  be edited through the UI.
- `data/exdunyayen/secrets.json` — per-user API keys. The relay
  token is seeded here.
- `data/_storage/` — user account records (handles, password
  hashes/salts, admin flags). The admin password is re-seeded from
  agenix on every start.
- `data/<other-user>/` — additional users' data.
- `extensions/` — symlinks to the bundled extensions (managed by
  tmpfiles).
- `plugins/` — symlink to `cl-helper` (managed by tmpfiles).
- `characters/`, `chats/`, `group chats/`, `user images/`, etc. —
  the actual data.
- `logs/` — service logs.

---

## Updating extensions

The bundled extensions are pinned in `flake.lock` and tracked via
flake inputs. To refresh them:

```bash
# Update one extension
nix flake update sillytavern-characterlibrary
# Or all
nix flake update
sudo nixos-rebuild switch --flake .
```

The extension sources live in the Nix store; `tmpfiles` recreates
the symlinks on every boot, so a `switch` is enough to pick up the
new revisions.

To add a new extension, declare it as a flake input in `flake.nix`,
add an entry to the `defaultExtensions` list in
`mon/sifa/servi/ai-chat/sillytavern.nix`, and rebuild.

---

## Troubleshooting

### Service won't start

```bash
journalctl -u sillytavern -n 50 --no-pager
```

Common causes:

- The seeder script failed. Look for `sillytavern-seed:` lines in the
  journal.
- yq or jq is missing — both are in the module's package set, so this
  should not happen unless the module is broken.

### "I can't connect" / blank page

Check the whitelist. If you're connecting from a non-Tailscale, non-localhost
IP, add it to the whitelist in the module and rebuild.

### Login rejected / forgot the admin password

The admin password comes from the agenix secret. Check:

```bash
ls -la /run/agenix/ayse-sillytavern
sudo journalctl -u sillytavern | grep -i "recover\|password"
```

The journal should show `User recovered. A program will exit now.`
from the seeder on each start. If the password still doesn't work,
re-set it:

```bash
nix run github:ryantm/agenix -- -e siri/ayse-sillytavern.age
sudo nixos-rebuild switch --flake .
```

### TTS doesn't work

1. Is Kokoro running? `systemctl status kokoro-tts`.
2. Hit Kokoro directly: `curl http://127.0.0.1:8880/health`.
3. In the SillyTavern TTS extension UI, click **Test** to send a
   direct request. Errors are echoed back.
4. Check the Kokoro dashboard's API call log — you should see the
   request with caller=SillyTavern.

### Chat doesn't work / 401 Unauthorized

The relay token isn't being read. Check:

```bash
ls -la /run/agenix/ayse-go-relay
cat /run/agenix/ayse-go-relay
```

If the file is empty or missing, agenix isn't decrypting the secret.
Check `siri/secrets.nix` for the public key matching ayse.

### Characters don't load

CharacterLibrary is fetching through FlareSolverr. Check:

```bash
systemctl status flaresolverr
journalctl -u flaresolverr -n 30
```

If FlareSolverr is down, characters from CharaVerse won't load.

### Extension is missing

`ls -la /var/lib/SillyTavern/extensions/`. The symlinks should be
recreated by tmpfiles on every boot. If they're missing:

```bash
sudo systemd-tmpfiles --create
sudo systemctl restart sillytavern
```

### "Listen address already in use"

Another process is on port 8000:

```bash
sudo ss -tlnp | grep 8000
```

Either kill it or change `drevosim.servi.sillytavern.port`.

---

## Service management

```bash
# Status
systemctl status sillytavern

# Start / stop / restart
sudo systemctl start sillytavern
sudo systemctl stop sillytavern
sudo systemctl restart sillytavern

# Live logs
journalctl -u sillytavern -f

# Last 50 log lines
journalctl -u sillytavern -n 50 --no-pager

# Seeder logs (in the same journal, look for "sillytavern-seed:")
journalctl -u sillytavern | grep sillytavern-seed
```

The service depends on `kokoro-tts.service` and is started after it.
If Kokoro is disabled, SillyTavern will still start (it doesn't hard-depend
on Kokoro being up at boot), but the TTS extension won't work until
Kokoro is back.

---

## Disable / reset

### Disable

```nix
# In mon/mehmangi/ayse/estandar.nix
drevosim.servi.sillytavern.enable = false;
```

Then `sudo nixos-rebuild switch --flake .`. The service is stopped
and removed; the state directory is left in place on `/persistent`.

### Reset to defaults

To wipe all user data and start fresh:

```bash
sudo systemctl stop sillytavern
sudo rm -rf /var/lib/SillyTavern
sudo systemctl start sillytavern
```

The seeder will recreate `config.local.yaml` and the default user
settings on the next start.

---

## Quick reference

```bash
# Status
systemctl status sillytavern

# Web UI
echo "http://$(hostname -I | awk '{print $1}'):8000"

# Logs
journalctl -u sillytavern -f

# Reset
sudo systemctl stop sillytavern
sudo rm -rf /var/lib/SillyTavern
sudo systemctl start sillytavern

# Update an extension
nix flake update sillytavern-characterlibrary
sudo nixos-rebuild switch --flake .
```

If something doesn't work, check `journalctl -u sillytavern -n 50`
first.
