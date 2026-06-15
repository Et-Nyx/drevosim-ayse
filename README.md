# Drevosim

A modular, declarative NixOS configuration flake built around the principle that **every program should be reproducible from a single source tree**, with desktop environments and tools assembled from composable, opinionated pieces rather than monolithic defaults.

Currently manages the `portaible` host (an external HD install) and is designed to scale to additional hosts via a host-driven, feature-driven module system.

---

## System Architecture

Drevosim is organized as a **dendritic module system** built on top of `flake-parts` and `import-tree`. The repository is split into distinct logical zones:

- **`mon/`** is the source-of-truth directory. Every `.nix` file in it is automatically evaluated; no central `imports = [ ... ]` lists need to be maintained.
- **`mon/mehmangi/<host>/`** contains the *per-host* configuration: hardware, users, host-level toggles. The `portaible` host is the only one with a full tree today; `ayse` is reserved.
- **`mon/sifa/<area>/`** is the *library of reusable features*. Each area is a coherent cluster (desktops, terminals, services, theming, etc.). Hosts enable features by setting options, not by writing imports.
- **`siri/`** holds `agenix`-encrypted secrets. Keys never enter the public repo; the flake decrypts them at build time.

The architecture is intentionally **declarative and deterministic**: rebuilding the system from the repo on a fresh install should produce the same binaries, the same configs in the same paths, and the same user-visible behavior. All wrapper modules pin source revisions and hashes; all user-level state is derived from `flake.lock`.

## Flake Logic (`flake.nix`)

`flake.nix` is deliberately small. It declares inputs and delegates output generation entirely to `flake-parts.lib.mkFlake`, passing the result of `inputs.import-tree ./mon` as the module tree:

```nix
{
  inputs = {
    nixpkgs.url        = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.05";
    nix-maid.url       = "github:viperML/nix-maid";
    import-tree.url    = "github:vic/import-tree";
    flake-parts.url    = "github:hercules-ci/flake-parts";
    wrapper-modules.url = "github:BirdeeHub/nix-wrapper-modules";
    agenix.url         = "github:ryantm/agenix";
    ...
  };
  outputs = inputs: inputs.flake-parts.lib.mkFlake
    { inherit inputs; }
    (inputs.import-tree ./mon);
}
```

The effect: any file added under `mon/` is automatically picked up; any option declared in any module is visible to every other module; hosts are wired up by listing which `nixosModules` they consume.

### Inputs of note

| Input | Role |
|---|---|
| `nixpkgs` (unstable) | The primary package source. All compositor, terminal, shell, bar, and tooling packages come from here. |
| `nixpkgs-stable` | Reserved for cases where upstream's unstable track breaks a critical app. |
| `flake-parts` | The module system that turns `mon/**/*.nix` into `flake.nixosModules.*` and `flake.nixosConfigurations.*`. |
| `import-tree` | Walks `mon/` and imports every `.nix` file found, producing the module tree. |
| `wrapper-modules` | BirdeeHub/nix-wrapper-modules. Provides the `wlib` library (`lib.evalPackage`, `lib.wrapPackage`, `wlib.modules.default`, plus a growing collection of pre-built wrapper modules for common programs). See *Configuration Strategy* below. |
| `nix-maid` | viperML/nix-maid. A drop-in for home-manager that uses `systemd.tmpfiles.d` rules + concurrent user systemd units to manage per-user $HOME files. Used as a fallback when wrapping is not appropriate. |
| `agenix` | Encrypted secrets, decrypted at activation time. Passwords, API keys, SSH keys land here. |

## Configuration Strategy: The Two-Layer Model

Drevosim treats every program as belonging to one of two layers:

1. **Wrap layer** — programs whose configuration can be baked into the package itself at build time. The result is a *portable, self-contained derivation* that any user or host can install and get the same behavior.
2. **Maid layer** — programs and data that must exist as a real file on disk in `$HOME` (or as a runtime service) and cannot be reasonably baked into a package.

The default is **wrap**. Maid is the fallback.

### What wrapping does

`nix-wrapper-modules` is a module-form reimplementation of `pkgs.makeWrapper`. It produces a wrapper derivation that, when run, sets environment variables, adds CLI flags, prepends packages to `PATH`, and optionally runs shell commands before exec'ing the original binary. The original binary's `$out/share/...` is also augmented with config files. The wrapper can use `${placeholder "out"}` in any of these so paths are computed at build time.

The available `wlib.modules.makeWrapper` options include:

| Option | Effect at runtime |
|---|---|
| `env = { VAR = value; }` | set env vars |
| `unsetVar = [ "VAR" ]` | unset env vars |
| `envDefault = { VAR = value; }` | set env vars only if currently unset |
| `prefixVar` / `suffixVar` + `prefixContent` / `suffixContent` | prepend/append to `:`-delimited vars (e.g., `PATH`, `LD_LIBRARY_PATH`) |
| `chdir = [ "/path" ]` | `cd` before exec |
| `runShell = [ "..." ]` | run shell commands before exec |
| `flags = { "--foo" = "bar"; }` | add CLI flags (with separator/ifs support) |
| `addFlag = [ "..." ]` | add positional flag strings |
| `appendFlag = [ "..." ]` | append to the end of argv |

Three backends are available: `nix` (default, allows runtime variable expansion), `shell` (`pkgs.makeWrapper`), `binary` (`pkgs.makeBinaryWrapper`). The choice matters mostly for very small wrapper size or for runtime-expansion needs.

### What wrapping is good for

Programs that read a config file at a path you can point to via env var or CLI flag. The wrapping is build-time only — no activation side effects, no per-user state, no DBus interaction.

### What nix-maid does

`nix-maid`'s `file` module produces `systemd.tmpfiles.d` rules. The pattern is a two-level static-directory:

```
$HOME/.config/river/init           -> $XDG_STATE_HOME/nix-maid/static
$XDG_STATE_HOME/nix-maid/static    -> $XDG_STATE_HOME/nix-maid/${hash}/static
$XDG_STATE_HOME/nix-maid/${hash}/static/river/init -> /nix/store/.../init
```

The two-level indirection gives atomic upgrades (the static-dir symlink is swapped to the new generation; all final paths re-resolve). Mustache syntax (`{{home}}`, `{{xdg_config_home}}`, `{{user}}`, `{{hash}}`) is resolved at activation time, so paths can depend on runtime values like `$USER` and `$HOME`.

nix-maid also exposes:
- `gsettings` — runs `gsettings set` at activation
- `kconfig` — writes to kconfig files at activation
- `systemd.services.*` — declares user systemd units (started concurrently)

### The boundary rule

> **Wrap** when the program reads a file at a path you control via env var or flag. **nix-maid** when the program or tool hardcodes a path under `~/` or `~/.config/`, or when the file is secret, runtime-mutated, or per-user state.

### Decision matrix (concrete examples)

| Concern | Layer | Why |
|---|---|---|
| Compositor (river / niri / hyprland) | wrap | reads `XDG_CONFIG_HOME/<comp>/init`; set that env var |
| Window manager (rill / kwm / machi) | wrap | reads `XDG_CONFIG_HOME/<wm>/config.*` |
| Bar (waybar) | wrap | upstream wrapper; reads JSON from any path |
| Launcher (fuzzel, anyrun) | wrap | upstream wrappers; reads INI from any path |
| Terminal (foot) | wrap | upstream wrapper; reads INI from any path |
| Shell (fish) | wrap | upstream wrapper; reads from any path |
| Notifier (mako) | wrap | upstream wrapper |
| Locker (swaylock) | wrap | upstream wrapper |
| Idle (swayidle) | wrap | upstream wrapper; flag-driven |
| Wallpaper (swww) | wrap | CLI-driven; no config file |
| Audio (pipewire, wireplumber) | NixOS `services.*` | not user-config files |
| Polkit agent | wrap | reads ini from any path |
| xdg-desktop-portal backends | NixOS `services.*` | declarative NixOS options |
| Theming (GTK, cursor, icons, fonts) | NixOS options | `environment.systemPackages`, `fonts.packages` |
| Color palette (kolor/) | hand-rolled or stylix | feeds into the above |
| Browser profile (LibreWolf/Firefox) | nix-maid | profiles are huge, runtime-mutated, per-user |
| gpg-agent, ssh-agent | nix-maid + NixOS `services.*` | symlink the configs, let the agent manage state |
| agenix secrets | nix-maid + `age.secrets.*` | never put secrets in a wrapped store path |
| Electron / VSCode settings.json | nix-maid | hardcoded `~/.config/...` paths, no `--config` flag |

### Defaulting order when adding a new program

1. Check upstream `nix-wrapper-modules` first. If a wrapper exists, use `inputs.wrapper-modules.wrappers.<name>.wrap { inherit pkgs; settings = ...; }`.
2. If upstream has no wrapper, write a local one in `mon/sifa/<area>/<name>.nix` using `inputs.wrapper-modules.lib.evalPackage` with `imports = [ wlib.modules.default ];`. This is the "roll your own" path, used for `river`, `river-classic`, `rill`, and future community WMs not yet packaged in nixpkgs.
3. If the program genuinely cannot be wrapped (hardcoded paths, runtime mutation, secrets, Electron-style settings), use `users.users.<name>.maid.file.xdg_config."<path>".source = ...;` inside `mon/mehmangi/<host>/ogarli.nix`.

## Module Conventions

### Option namespace

Two parallel option trees exist:

- **`drevosim.*`** is the flake-parts-level namespace, declared in `mon/parts.nix`. It holds project-wide options available in any flake-parts module. The single option today is `drevosim.userName` (the user the system is built around). It is re-exposed as a NixOS option in host modules so the nix-maid config and `users.users.${name}` plumbing can read it.
- **`taluji.*`** is the per-user NixOS option namespace. `taluji.userName` carries the resolved username into `nix-maid`'s `users.users.<name>.maid` config.

### Orchestrator + sub-module pattern

A feature that has *internal alternatives* (e.g. the River compositor with `classic` vs `rill` window managers) is split into:

- One **orchestrator** module declaring the umbrella options (`enable`, the alternative-enum, any cross-cutting concerns like the display-manager default session).
- One or more **sub-modules** that expose the per-alternative options, the wrapped derivations, and any file/path options for that alternative.

The orchestrator's `config = lib.mkIf opsyon.enable { ... }` block is the **only** place that decides which sub-module's package actually ends up in `environment.systemPackages`. This keeps the resolution logic in one place and avoids merge conflicts between sub-modules.

Each sub-module's options live under a *sibling* path of the orchestrator's namespace, e.g. `drevosim.sifa.mesa.riverClassic.*` and `drevosim.sifa.mesa.rill.*`, so they never collide with the orchestrator's `drevosim.sifa.mesa.river.*` options.

### File layout inside a feature

```
mon/sifa/<area>/<feature>/
├── <feature>.nix        # orchestrator: enable, alternatives enum, system-level config
├── <alt-a>.nix          # sub-module: per-alt options, wrapped derivation, init file path option
├── <alt-b>.nix          # sub-module: ...
└── defaults/            # external default config files, referenced by the sub-modules
    ├── <alt-a>-init.sh
    └── <alt-b>-config.<ext>
```

External default files (in `defaults/`) are preferred over inline string defaults for anything non-trivial — they get syntax highlighting in editors, avoid Nix string-escaping pain, and are easier to maintain.

### Local derivations for non-nixpkgs programs

Programs that are not (yet) in nixpkgs (e.g. `rill`, future `kwm`, `machi`) get their own `stdenv.mkDerivation` next to the wrapper that uses them. Sources are pinned via `pkgs.fetchFromCodeberg` / `pkgs.fetchFromGitHub` to a specific tag, with `hash = "...";` computed by `nix-prefetch`. The build expression lives in the same `mon/sifa/<area>/<feature>/` directory as the wrapper, not in a separate flake input — `flake.nix` stays clean.

## The Compositor Layer: River (in progress)

The first feature being assembled under this model is a River-based compositor stack. River is a non-monolithic Wayland compositor: as of 0.4.x, it is *only* a compositor, and requires a separate window manager implementing the `river-window-management-v1` protocol. The pre-0.4 monolithic version is maintained as **River-Classic** (up to 0.3.x).

Both versions are in nixpkgs:

- `pkgs.river` — 0.4.x. New split stack. Installs `share/wayland-sessions/river.desktop`.
- `pkgs.river-classic` — 0.3.x. Monolithic dynamic tiler. Also installs `share/wayland-sessions/river.desktop` (same session name `river`).

The third leg, **rill** (a minimalist scrolling WM for the new River), is not in nixpkgs and has no upstream `flake.nix`; it will be built from source.

### River module layout (planned)

```
mon/sifa/mesa/river/
├── river.nix            # orchestrator: drevosim.sifa.mesa.river.{enable,janela,defaultSession}
├── river-classic.nix    # sub-module for janela = "classic": wrapped pkgs.river-classic + init path
├── rill.nix             # sub-module for janela = "rill": local rill build + wrapped rill + new-river init
└── defaults/
    ├── river-classic-init.sh    # default init for river-classic (just `river`)
    └── river-rill-init.sh        # default init for new river + rill (`exec rill`)
```

The `janela` enum is the user-facing switch:

```nix
drevosim.sifa.mesa.river = {
  enable = true;
  janela = "classic";   # or "rill"
};
```

The orchestrator's `config = lib.mkIf opsyon.enable { ... }` block selects exactly one of:
- the wrapped `river-classic` derivation (default — the 0.3.x monolith), or
- the wrapped new `river` derivation *and* the locally-built wrapped `rill` derivation.

Crucially, **both `pkgs.river` and `pkgs.river-classic` never get installed simultaneously** — they collide on `share/wayland-sessions/river.desktop` and on the `river` binary in `PATH`. The orchestrator is the sole resolver of which one is in the system.

### What the user-facing config options will look like

```nix
# mon/mehmangi/portaible/estandar.nix (host-level)
{
  drevosim.sifa.mesa.river = {
    enable  = true;
    janela  = "rill";
  };
}
```

Optional overrides (in `ogarli.nix` or per-host file):

```nix
{
  drevosim.sifa.mesa.river.rill = {
    initPath    = ./my-rill-init.sh;        # default: ./mon/sifa/mesa/river/defaults/river-rill-init.sh
    configPath  = ./my-rill-config.zon;     # default: ./mon/sifa/mesa/river/defaults/rill-config.zon
  };
}
```

The init scripts and config files are store-symlinked into the wrapped package's `$out/share/...` at build time, then `XDG_CONFIG_HOME=$out/share` is set in the wrapper, so the programs find their configs without any `$HOME` files needing to exist.

### Upstream wrapper-modules inventory (relevant subset)

The following programs have pre-built wrappers in `wrapper-modules` and will be consumed via `inputs.wrapper-modules.wrappers.<name>.wrap` rather than authored locally:

- Compositors / shells: `niri`, `noctalia-shell`, `mangowc`
- Bars: `waybar`
- Launchers: `fuzzel`, `rofi`
- Terminals / shells: `foot`, `fish`, `wezterm`, `nushell`
- Notifications / idle / lock: `mako`, `swayidle`, `swaylock`
- Editors / media / utilities: `neovim`, `mpv`, `fastfetch`, `starship`, `mdbook`, `notmuch`
- Misc: `nh` (nix helper), `wl-kbptr`, `wlr-which-key`

Programs without an upstream wrapper that Drevosim will author locally: `river` (new), `river-classic`, `rill` (and any future community WMs not yet in nixpkgs).

## Directory Structure

```text
Drevosim/
├── flake.nix        # Flake inputs and automated output generation
├── flake.lock       # Pinned versions of every input
├── README.md        # This file
├── mon/             # Root directory for all system and feature modules (auto-imported)
│   ├── parts.nix    # Flake-parts level options (systems, drevosim.userName)
│   ├── mehmangi/    # Host-specific configurations (machines)
│   │   ├── ayse/    # Configuration for a future host (currently empty)
│   │   └── portaible/ # Main portable host (external HD install)
│   │       ├── estandar.nix # Standard options interface to toggle modules
│   │       ├── estrutur.nix # Core system configuration (boot, networking, locale, time, agenix)
│   │       ├── hardwer.nix  # Hardware-specific generation and settings
│   │       └── ogarli.nix   # User and home environment definitions
│   └── sifa/        # Reusable feature modules
│       ├── browsetul/ # Web browsers (e.g., LibreWolf)
│       ├── kolor/     # Theming and color palettes
│       ├── kuflu/     # Display managers / lock screens (e.g., Ly)
│       ├── medya/     # Media tools and players
│       ├── mesa/      # Desktop environments and window managers
│       │   └── river/ # River compositor (orchestrator + classic/rill sub-modules) — in progress
│       ├── produti/   # Productivity software and editors (Neovim, Zed)
│       ├── servi/     # Background services and daemons (Kanshi, etc.)
│       ├── terminal/  # Terminal emulators and shells (Fish, Foot)
│       ├── yongu/     # Utilities and application launchers (Fuzzel)
│       └── yuxi/      # Games and related software
└── siri/            # Secret management
    ├── secrets.nix  # agenix configuration mapping public keys to secrets
    └── *.age        # age-encrypted secret files (passwords, keys)
```

### Breakdown of key directories

- **`mon/`**: The core source directory of the configuration. Everything inside is automatically evaluated by `import-tree`. New files integrate into the module system without editing any central file.
- **`mon/mehmangi/<host>/`**: Per-host definitions. Each host orchestrates its hardware profile, enables specific features via the standardized options interface, and defines the user environment.
- **`mon/sifa/<area>/`**: Library of reusable features. Each subdirectory groups related software or configurations. A new host opts in to a tool by setting `drevosim.sifa.<area>.<feature>.enable = true;` in its `estandar.nix`.
- **`siri/`**: Security enclave. `agenix` keeps all sensitive data encrypted in the repository and decrypted only at activation time on the target host.

## Design Goals (Recap)

- **Declarative**: The entire system is described in Nix expressions. No imperative scripts run during activation beyond what NixOS's standard activation handles.
- **Reproducible**: `flake.lock` pins every input. Hashes are baked into derivations. Building on a fresh machine produces the same outputs.
- **Deterministic**: No build-time fetchers that bypass `flake.lock`. No system path outside `/nix/store` for config files (except where wrapping is impossible, in which case nix-maid handles it via store-symlinks through its static directory).
- **Modular**: A new program is added by dropping a new `<name>.nix` in the right `sifa/<area>/` directory. A new host is added by adding a directory under `mehmangi/` and wiring it into `flake.nix` (or letting `import-tree` do it automatically).
- **Composable**: Features are enabled by option, not by import. A new host picks the tools it wants without copying configuration logic.

## Setup (Brief)

```sh
# 1. Clone
git clone <repo-url> drevosim
cd drevosim

# 2. Generate a host key for agenix (one-time, on a trusted machine)
agenix -g  # creates keys/ and prints a public key

# 3. Add the public key to siri/secrets.nix, then rekey existing secrets
#    so they are decryptable by the new host.

# 4. Pick or add a host under mon/mehmangi/<host>/, set the right
#    hardware UUIDs in hardwer.nix, and adjust ogarli.nix.

# 5. Build
nixos-rebuild switch --flake .#<host>
```

For secrets rotation, see the `agenix` documentation. The `siri/` directory is the only part of the repo that holds encrypted material; everything else is plain text under version control.

## License

TBD. Treat the repo as private until a license is added.
