# Preservation (Ephemeral Root) — Operator's Manual

A practical guide to the [preservation](https://github.com/nix-community/preservation)
setup on `ayse`. Read this when you need to add a new preserved
directory, understand what survives a reboot, or debug a state-loss
mystery.

`ayse` is an **impermanent (ephemeral) NixOS host**: `/` is a `tmpfs`
that is rebuilt from scratch on every boot. This guide documents
what is preserved where, and how to add new preservation rules.

---

## Table of contents

- [What "impermanent" means here](#what-impermanent-means-here)
- [The big picture](#the-big-picture)
- [What is preserved on `/persistent`](#what-is-preserved-on-persistent)
- [What is intentionally NOT preserved](#what-is-intentionally-not-preserved)
- [Boot sequence](#boot-sequence)
- [How preservation works](#how-preservation-works)
- [The `preserveAt` rules](#the-preserveat-rules)
- [Adding new preservation rules](#adding-new-preservation-rules)
- [Common gotchas](#common-gotchas)
- [Verifying what survived a reboot](#verifying-what-survived-a-reboot)
- [Manual recovery](#manual-recovery)

---

## What "impermanent" means here

- `/` is a `tmpfs` created at every boot. **Everything in `/` is
  ephemeral** unless explicitly preserved.
- `/home` is also `tmpfs`, rebuilt on every boot.
- `/nix` is a **Btrfs subvolume on the SSD**, persisted across
  reboots. It holds the Nix store, the system profiles, and the boot
  loader state. `/nix` is the only directory the system actively
  *writes to* in normal operation.
- `/persistent` is a **Btrfs partition on the HDD**. This is where
  preservation rules copy state to/from. All preserved state ends
  up here, and is restored from here on the next boot.

The system is "NixOS as a stateless container" — the OS itself is
disposable, and only the things we explicitly preserve survive
reboots.

---

## The big picture

```
┌─────────────────────────────── SSD ────────────────────────────────┐
│  /dev/nvme0n1                                                     │
│  ┌─────────────┬─────────┬────────────────────────────────────┐  │
│  │ ESP (vfat)  │  swap   │  Btrfs (root)                      │  │
│  │ /boot       │         │  ├─ @nix subvolume → /nix          │  │
│  │             │         │  └─ flat subvolumes (other Btrfs)  │  │
│  └─────────────┴─────────┴────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────┘

┌─────────────────────────────── HDD ────────────────────────────────┐
│  /dev/sda                                                         │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ Btrfs (zstd compression)                                   │  │
│  │ └─ /persistent                                              │  │
│  │     ├─ etc/ssh/            ← preserved host SSH keys       │  │
│  │     ├─ var/lib/bluetooth/  ← pairing keys                  │  │
│  │     ├─ var/lib/NetworkManager/system-connections/          │  │
│  │     ├─ var/lib/nixos/      ← user/group DB                │  │
│  │     ├─ var/lib/kokoro-tts/ ← TTS state (custom voices)     │  │
│  │     ├─ var/lib/SillyTavern/ ← SillyTavern data            │  │
│  │     ├─ var/lib/ftp-srv/    ← anonymous FTP root            │  │
│  │     ├─ home/eter/          ← preserved user home subtree   │  │
│  │     └─ nixos/              ← the flake checkout           │  │
│  └────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────┘
```

---

## What is preserved on `/persistent`

### System state

| Path | Why |
|------|-----|
| `/etc/ssh` | Host SSH keys. agenix reads these directly from `/persistent/etc/ssh` as its identity, so this must be preserved. |
| `/var/lib/bluetooth` | Bluetooth pairing keys. |
| `/var/lib/NetworkManager/system-connections` | Saved Wi-Fi / VPN profiles and connection secrets. |
| `/var/lib/nixos` | NixOS user/group database. Needed **early in boot** so uids/gids are stable. |
| `/var/lib/kokoro-tts` | TTS service state, including custom `.pt` voice packs uploaded through the dashboard. |
| `/var/lib/SillyTavern` | SillyTavern data (characters, chats, settings, secrets). |
| `/var/lib/ftp-srv` | Anonymous FTP root, including the writable `upload/` subdirectory. |
| `/etc/machine-id` | Machine ID. Preserved **early in boot** so systemd does not regenerate it. |

### User state (`eter`)

| Path | Why |
|------|-----|
| `~/.config` | Broad application and desktop configuration: KDE Plasma, Chromium, KWallet. (Transitional — will be narrowed as dotfiles move into Nix.) |
| `~/.local/share` | Broad application data. |
| `~/.local/state` | Application state (e.g. KWallet, Plasma state). |
| `~/.ssh` | User SSH keys and `known_hosts`. |
| `~/Desktop` | XDG user folder. |
| `~/Documents` | XDG user folder. |
| `~/Downloads` | XDG user folder. |
| `~/Games` | XDG user folder. Used by Heroic and Steam for large game installs that would otherwise fill the tmpfs root. |
| `~/Music` | XDG user folder. |
| `~/Pictures` | XDG user folder. |
| `~/Projects` | XDG user folder. |
| `~/Public` | XDG user folder. |
| `~/Templates` | XDG user folder. |
| `~/Videos` | XDG user folder. |

The whole `home/eter` subtree is preserved under
`/persistent/home/eter`, so the home directory and all its preserved
children are recreated with `eter:users` ownership.

---

## What is intentionally NOT preserved

- **`/var/log`** — boot logs are written to RAM (`journald` with
  `Storage=volatile`). This keeps `/persistent` clean and matches
  the "ephemeral" philosophy. Logs survive only the current boot.
- **Browser cache and runtime state** — they live under `~/.cache`
  (not in the preserved list), so the browser rebuilds its cache
  on every boot. This is fine for a private machine; the actual
  user data (bookmarks, history) lives in `~/.config` and is
  preserved.
- **Old Nix store generations** — `/nix` is preserved but the
  automatic GC keeps only generations newer than 7 days. The store
  itself is not pruned beyond that.
- **Anything in `/tmp` or `/run`** — by design, these are
  tmpfs-backed and never survive a reboot.
- **Docker / Podman images and containers** — `ayse` does not run
  Docker or Podman.
- **Generated audio from Kokoro TTS** — the TTS service streams
  audio directly to the client; nothing is written to disk.

---

## Boot sequence

The order matters: some things must be preserved **in the initrd**
(early boot), others only in the main system.

```
initrd                          main system
────────                        ───────────
1. /var/lib/nixos    ← inInitrd  (preserved, user/group DB)
2. /etc/machine-id   ← inInitrd  (preserved, machine ID)

then root pivot                  3. /etc/ssh          (preserved, host keys)
                                 4. /var/lib/bluetooth (preserved, pairing)
                                 5. /var/lib/NetworkManager/system-connections
                                 6. /var/lib/kokoro-tts
                                 7. /var/lib/SillyTavern
                                 8. /var/lib/ftp-srv
                                 9. /home/eter        (preserved, user subtree)
```

If `/var/lib/nixos` is not preserved **in the initrd**, early
services that look up user/group info (e.g. SSH host key generation,
systemd userdb) will see different uids every boot and break
`/etc/shadow` consistency. The `users.mutableUsers = false` NixOS
default requires this.

If `/etc/machine-id` is not preserved in the initrd, systemd
regenerates it on every boot, breaking journald correlation,
Tailscale node identity, etc.

---

## How preservation works

The `preservation` module ([source](https://github.com/nix-community/preservation))
hooks into the boot process in both directions:

### On shutdown

`preservation` walks each `directories` / `files` entry and copies
the current state of the path **on the live system** to the
corresponding location on `/persistent`. This is a "snapshot" before
the next boot.

### On boot

`preservation` walks each entry in the opposite direction, copying
the snapshot from `/persistent` back onto the new tmpfs root before
services start.

The mechanism is `systemd` service units that run at the right
phase (`initrd-cleanup` for initrd entries, `local-fs.target` for
the main system). The actual copying is `cp -a --reflink=auto`
under the hood, which is fast on Btrfs (reflink = cheap CoW).

### The `users.eter` subtree

`users.eter = { directories = [ ... ]; }` is a special form that
preserves the per-user subtree. On the persistent side, the
contents are at `/persistent/home/eter/<subdir>`. On the
non-persistent side, the home directory is recreated with
`eter:users` ownership, and each preserved subdir is copied in.

---

## The `preserveAt` rules

The full rules live in
`mon/mehmangi/ayse/nukleus/preservation.nix`. Here's the structure
with annotations:

```nix
preservation = {
  enable = true;

  preserveAt."/persistent" = {
    directories = [
      # Each entry is either a string (default ownership) or
      # an attrset with `directory`, `user`, `group`, `mode`,
      # and (for early-boot entries) `inInitrd = true`.

      "/etc/ssh"                              # SSH host keys
      "/var/lib/bluetooth"                    # pairing
      "/var/lib/NetworkManager/system-connections"

      {
        directory = "/var/lib/nixos";
        inInitrd = true;          # ← preserved during initrd
      }
    ];

    files = [
      {
        file = "/etc/machine-id";
        inInitrd = true;          # ← preserved during initrd
      }
    ];

    users.eter = {
      directories = [
        ".config"   ".local/share"   ".local/state"
        ".ssh"
        "Desktop"   "Documents"   "Downloads"   "Games"
        "Music"     "Pictures"    "Projects"    "Public"
        "Templates" "Videos"
      ];
    };
  };
};
```

### The systemd tweak

```nix
systemd.services.systemd-machine-id-commit.enable = false;
```

This disables the systemd-machine-id-commit service, which would
otherwise try to commit a transient machine-id back to disk on
shutdown. With preservation, `/etc/machine-id` is already managed
by us, so we don't want systemd's default behaviour.

---

## Adding new preservation rules

Two patterns: **system path** and **per-user path**.

### System path (e.g. a new service's state dir)

If a service stores state under `/var/lib/<name>/` and you want it
to survive reboots:

```nix
# In mon/mehmangi/ayse/nukleus/preservation.nix
preservation.preserveAt."/persistent".directories = [
  # ... existing entries ...
  {
    directory = "/var/lib/my-service";
    user = "my-service";
    group = "my-service";
    mode = "0750";
  }
];
```

The `user`, `group`, and `mode` are applied when the directory is
restored on boot. They're optional — omit them to inherit the
default (`root:root`, `0755`).

### Per-user path (e.g. a new XDG folder or app data dir)

If you want to preserve a per-user path under the `eter` home:

```nix
# In mon/mehmangi/ayse/nukleus/preservation.nix
users.eter.directories = [
  # ... existing entries ...
  ".local/share/my-app"   # app data
  "MyStuff"               # custom folder, becomes ~/MyStuff
];
```

The path is interpreted relative to the home directory. The whole
subtree is recreated with `eter:users` ownership.

### Early-boot (initrd) entry

For paths that must be available before the main system starts
(typically `/var/lib/nixos` and `/etc/machine-id`):

```nix
{
  directory = "/var/lib/my-early-thing";
  inInitrd = true;
}
```

Most paths do **not** need `inInitrd = true`. Only use it when a
service that runs before `/persistent` is fully mounted needs the
data.

### Applying the change

```bash
sudo nixos-rebuild switch --flake .
```

The new rules take effect on the **next** reboot. State written
between the rebuild and the next reboot is at risk if the system
crashes — back it up manually if it matters.

---

## Common gotchas

### "I added a rule but the directory is empty after reboot"

You added the rule but didn't **reboot**. Preservation snapshots
happen at shutdown. A `switch` doesn't trigger a snapshot of the
new rules. Reboot.

### "Files I created in `/var/lib/<x>/` are gone after reboot"

The path isn't in the preserveAt list. Add it.

### "My service fails to start with 'permission denied'"

The preserved directory was restored with the wrong ownership. Add
explicit `user` and `group` to the preserveAt entry:

```nix
{
  directory = "/var/lib/my-service";
  user = "my-service";
  group = "my-service";
}
```

### "`users.eter.directories` doesn't seem to apply"

The user subtree only works for the **declared** user. Make sure
`users.eter` is the right user (this repo uses `eter`).

### "Boot is slow / boot is hanging"

`/persistent` is on a slow HDD. If you have a lot of preserved
state, the copy on shutdown (and on boot) takes time. Check:

```bash
du -sh /persistent/*
```

If one path is huge, narrow it: instead of preserving the whole
`~/.config`, preserve only the specific subdirectories the app
needs.

### "The system is full because `/persistent` is filling up"

`/persistent` is a Btrfs partition. Check usage:

```bash
df -h /persistent
du -sh /persistent/* | sort -h
```

Common culprits:

- `~/Games` (Steam, Heroic caches)
- `~/.cache` (if you accidentally preserved it)
- Old Nix store generations (handled by automatic GC, but the GC
  only keeps 7 days)

The system has no automatic cleanup of preserved state — you have
to manage it.

### "I rebooted and lost `/var/log`"

That's by design. Logs are in `journald` with `Storage=volatile`.
Use `journalctl -b 0` to see this boot's logs, `journalctl -b -1`
for the previous one (only if you didn't reboot since).

---

## Verifying what survived a reboot

After a reboot, the fastest way to see what preservation
restored:

```bash
# System state
ls -la /etc/ssh/          # host keys
ls -la /var/lib/bluetooth/
ls -la /var/lib/NetworkManager/system-connections/
ls -la /var/lib/nixos/
cat /etc/machine-id

# Service state
ls /var/lib/kokoro-tts/voices/   # custom voices
ls /var/lib/SillyTavern/         # SillyTavern data
ls /var/lib/ftp-srv/upload/      # uploaded files

# User state
ls -la ~ | head -20
ls ~/.config/
ls ~/.local/share/
```

To see exactly what was copied during the last boot:

```bash
journalctl -u preservation-apply-* --no-pager | head -50
```

(The exact unit name depends on the preservation version, but the
prefix is consistent.)

---

## Manual recovery

If preservation breaks and the system won't boot:

1. From a NixOS installer USB, mount the persistent partition:
   ```bash
   mount /dev/sda /mnt
   ls /mnt
   ```
2. Your state is there. Copy it off to a safe location:
   ```bash
   rsync -av /mnt/home/eter/ /external/eter-backup/
   rsync -av /mnt/var/lib/ /external/state-backup/
   ```
3. Reinstall NixOS using `nixos-install --flake .#ayse`.
4. Restore the data:
   ```bash
   rsync -av /external/eter-backup/ /persistent/home/eter/
   rsync -av /external/state-backup/ /persistent/var/lib/
   ```
5. Reboot.

The persistent partition is independent of the NixOS install —
reinstalling NixOS does not touch `/persistent`. The preservation
rules in the new install will pick up the existing state on the
next boot.

---

## Quick reference

```bash
# What's preserved?
cat mon/mehmangi/ayse/nukleus/preservation.nix

# What's actually on /persistent right now?
du -sh /persistent/* | sort -h

# Verify a specific path is preserved
ls -la /var/lib/kokoro-tts/   # should show your custom voices

# Disk usage
df -h /persistent

# Boot logs for preservation
journalctl -u preservation-* | head -30
```

If a service's state isn't surviving a reboot, the fix is almost
always "add a preservation rule for it". See [Adding new
preservation rules](#adding-new-preservation-rules).
