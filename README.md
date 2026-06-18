# Drevosim

A dendritic NixOS configuration with homeless dotfiles, built on [flake-parts](https://github.com/hercules-ci/flake-parts), [import-tree](https://github.com/vic/import-tree), [nix-wrapper-modules](https://github.com/BirdeeHub/nix-wrapper-modules), and [nix-maid](https://github.com/viperML/nix-maid).

The layout branches like a tree: a single flake root feeds a trunk of module directories, which split into hosts, features, helpers, and secrets.

## Layout

```text
.
├── flake.nix         # flake definition
├── mon/              # module tree (imported recursively by import-tree)
│   ├── parts.nix     # flake-parts configuration
│   ├── basi.nix      # shared base options (drevosim.userName, nix settings, unfree)
│   ├── mehmangi/     # host machines
│   │   └── portaible/
│   │       ├── estandar.nix   # host assembler
│   │       ├── ogarli.nix     # user config
│   │       ├── loka.nix       # timezone, locale, and keymaps
│   │       └── nukleus/       # core host config
│   │           ├── estrutur.nix
│   │           ├── hardwer.nix
│   │           └── xoru.nix
│   └── sifa/         # feature modules
│       ├── kuflu/    # security & login
│       │   ├── ly.nix           # ly display-manager module
│       │   ├── swaylock.nix     # swaylock screen locker module
│       │   └── faylu/
│       │       ├── ly.ini       # ly configuration file
│       │       └── swaylock.conf # swaylock configuration file
│       ├── mesa/     # window managers & compositors
│       │   └── river/
│       │       ├── river.nix    # river wrapper module
│       │       ├── canoe.nix    # canoe package + wrapper
│       │       ├── rill.nix     # rill package + wrapper
│       │       └── faylu/       # rill/canoe configuration files
│       │           ├── canoe.toml
│       │           └── rill.zon
│       ├── medya/    # audio / video
│       │   └── pipewire.nix     # PipeWire + WirePlumber audio stack
│       ├── programa/ # general programs
│       │   ├── fuzzel.nix       # fuzzel launcher module
│       │   ├── tul.nix          # simple config-free tools
│       │   └── faylu/
│       │       └── fuzzel.ini   # fuzzel configuration file
│       ├── servi/    # system services
│       │   └── openssh.nix      # OpenSSH daemon
│       └── terminal/ # terminal/console tools
│           ├── foot.nix
│           ├── fish.nix
│           ├── nushell.nix
│           └── faylu/
│               ├── foot.ini
│               ├── config.fish
│               └── config.nu

├── offolo/           # offline / external build dependencies
│   └── rill.nix      # zig dependencies for rill
├── yongu/            # helper functions
│   ├── monlari.nix   # recursive NixOS module collector
│   ├── parseIni.nix  # pure-Nix INI parser for faylu files
│   └── parseSwaylock.nix # pure-Nix swaylock config parser
└── siri/             # secrets managed by agenix
```

## Naming

Most directory and file names use a small project-specific vocabulary instead of plain English:

| Term | Meaning |
|------|---------|
| `mon` | modules (the whole module tree) |
| `mehmangi` | machines / hosts |
| `sifa` | features / capabilities |
| `siri` | secrets |
| `basi` | shared base options |
| `ayse` | (reserved for additional hosts) |
| `portaible` | portable NixOS host |
| `estandar` | standard / host configuration assembler |
| `estrutur` | structure / base system config |
| `hardwer` | hardware configuration |
| `ogarli` | user configuration |
| `loka` | locale, timezone, and keymaps |
| `xoru` | core boot / kernel config |
| `nukleus` | core host configuration directory |
| `kolor` | theming & customization |
| `kuflu` | security & login |
| `ly` | ly TUI display manager |
| `medya` | media |
| `mesa` | window managers & compositors |
| `produti` | productivity |
| `programa` | general programs |
| `servi` | services |
| `terminal` | terminal/console tools |
| `tul` | simple configuration-free tools |
| `yuxi` | gaming |
| `offolo` | offline / external build dependencies |
| `yongu` | helper functions |
| `monlari` | recursive module collector |
| `parseIni` | pure-Nix INI parser |
| `parseSwaylock` | pure-Nix swaylock config parser |
| `faylu` | configuration files |
| `misuRill` | wrapped rill package |
| `misuRiver` | wrapped river package |
| `misuCanoe` | wrapped canoe package |
| `misuFoot` | wrapped foot package |
| `misuFuzzel` | wrapped fuzzel package |
| `misuSwaylock` | wrapped swaylock package |
| `misuFish` | wrapped fish package |
| `misuNushell` | wrapped nushell package |

## How modules are loaded

`import-tree ./mon` recursively imports every `.nix` file under `mon/` as a flake-parts module. Each module can export `flake.nixosModules.<path>`.

Paths containing `/faylu/` are filtered out of `import-tree`, because `faylu/` directories hold raw configuration files (INI, fish, nushell, TOML, Zig manifests) rather than Nix modules:

```nix
outputs = inputs: inputs.flake-parts.lib.mkFlake
  { inherit inputs; }
  (inputs.import-tree.filterNot (p: inputs.nixpkgs.lib.hasInfix "/faylu/" p) ./mon);
```

Host configs do not list feature modules individually. Instead, `mon/mehmangi/portaible/estandar.nix` uses `yongu.monlari` to recursively collect all modules under `self.nixosModules.sifa` and `self.nixosModules.portaible`:

```nix
{ self, inputs, ... }:
let
  lib = inputs.nixpkgs.lib;
  yongu = import "${self}/yongu/monlari.nix" { inherit lib; };
in
{
  flake.nixosConfigurations.portaible = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      inputs.nix-maid.nixosModules.default
      inputs.agenix.nixosModules.default
      self.nixosModules.basi

      ({ ... }: {
        imports =
          yongu.monlari (self.nixosModules.sifa or {}) ++
          yongu.monlari (self.nixosModules.portaible or {});
      })
    ];
  };
}
```

`yongu/monlari.nix` walks nested attribute sets and collects every function it finds, so it does not matter whether a module is exported as `sifa.river`, `sifa.mesa.river`, or `sifa.mesa.river.classic`.

## Options

Feature modules expose options under `drevosim.<category>.<module>` so they can be enabled and configured from the host assembler:

```nix
drevosim = {
  kuflu = {
    ly.enable = true;
    swaylock.enable = true;
  };
  mesa.river = {
    enable = true;
    janela = "canoe";   # "rill" | "canoe"
  };
  terminal = {
    foot.enable = true;
    fish = {
      enable = true;
      defaultUserShell = true;
      shellAliases.ll = "ls -la";
    };
    nushell = {
      enable = true;
      defaultUserShell = false;
    };
  };
  programa = {
    fuzzel.enable = true;
  };
};
```

## Wrapper modules

The project uses nix-wrapper-modules to create homeless, store-path-based configurations for programs. Each wrapper sets `XDG_CONFIG_HOME` to a generated directory inside the Nix store, so the programs read their configs from there instead of from `~/.config`.

### Rill

`mon/sifa/mesa/river/rill.nix` packages and wraps [rill](https://codeberg.org/lzj15/rill), a scrolling window manager for river. Because rill is not in nixpkgs, it is built from source with `pkgs.fetchFromCodeberg`. Its Zig dependencies are vendored in `offolo/rill.nix`.

The wrapped package is `.#misuRill`. It bakes `mon/sifa/mesa/river/faylu/rill.zon` into the store and sets `XDG_CONFIG_HOME` so rill finds its config.

### Canoe

`mon/sifa/mesa/river/canoe.nix` packages and wraps [canoe](https://github.com/esterlicht/canoe), another river layout generator. Because canoe is not in nixpkgs, it is built from source with `pkgs.fetchFromGitHub` and `buildRustPackage`.

The wrapped package is `.#misuCanoe`. It bakes `mon/sifa/mesa/river/faylu/canoe.toml` into the store.

### River

`mon/sifa/mesa/river/river.nix` wraps the [river](https://codeberg.org/river/river) Wayland compositor. The module exposes `drevosim.mesa.river.enable` and `drevosim.mesa.river.janela`:

- `janela = "rill"` generates a `river/init` that execs `misuRill`
- `janela = "canoe"` generates a `river/init` that execs `misuCanoe`

The wrapped session package is `.#misuRiver`. It provides a `providedSessions` attribute so it can be listed by display managers like ly.

### ly

`mon/sifa/kuflu/ly.nix` enables the [ly](https://github.com/fairyglade/ly) TUI display manager. Its default settings are read from `mon/sifa/kuflu/faylu/ly.ini` using `yongu/parseIni.nix`, a pure-Nix INI parser. The module then passes them to `services.displayManager.ly.settings`.

Because the NixOS ly module already supplies correct defaults for paths, session directories, and power commands, the upstream defaults in `ly.ini` that would override those are commented out. Only appearance and behavior overrides are left active.

### Fuzzel

`mon/sifa/programa/fuzzel.nix` wraps [fuzzel](https://codeberg.org/dnkl/fuzzel), a Wayland application launcher. Like `foot`, it reads its default INI config from `mon/sifa/programa/faylu/fuzzel.ini` via `yongu/parseIni.nix`.

The wrapped package is `.#misuFuzzel`. It is enabled with `drevosim.programa.fuzzel.enable = true`.

### Swaylock

`mon/sifa/kuflu/swaylock.nix` wraps [swaylock](https://github.com/swaywm/swaylock), a screen locker for Wayland. It reads its default config from `mon/sifa/kuflu/faylu/swaylock.conf` via `yongu/parseSwaylock.nix`.

The wrapped package is `.#misuSwaylock`. It is enabled with `drevosim.kuflu.swaylock.enable = true`. The module also creates the PAM service required for swaylock to authenticate.

### Terminal programs

`mon/sifa/terminal/` contains wrapped terminal programs:

- `foot.nix` — reads `faylu/foot.ini` via `parseIni`
- `fish.nix` — reads `faylu/config.fish` as raw text
- `nushell.nix` — reads `faylu/config.nu` as raw text

The wrapped packages are `.#misuFoot`, `.#misuFish`, and `.#misuNushell`. Their NixOS options remain overridable from `estandar.nix`, while their default contents live in syntax-highlighted faylu files.

`foot` and `fish` use nix-wrapper-modules directly. `nushell` deviates slightly: because nushell writes runtime files (`history.txt`, `plugin.nu`) next to its config, it cannot keep `XDG_CONFIG_HOME` in the read-only store. Instead, `.#misuNushell` copies `config.nu` and `env.nu` into a writable directory (`~/.config/nushell` when `HOME` is set, otherwise `/run/user/<uid>/nushell` or `/tmp/nushell-<uid>`) before launching the real nushell binary. It also exposes `shellPath = "/bin/nu"` so it can be used as `users.defaultUserShell`.

## Hosts

The only host defined so far is `portaible`. It is assembled automatically from:

- `inputs.nix-maid.nixosModules.default` — nix-maid user environment
- `inputs.agenix.nixosModules.default` — secret decryption
- `self.nixosModules.basi` — shared base config (`drevosim.userName`, nix settings, unfree)
- `self.nixosModules.portaible.*` — host-specific modules (`estandar`, `ogarli`, `loka`, `nukleus.*`)
- `self.nixosModules.sifa.*` — feature modules (`kuflu.ly`, `mesa.river`, `medya.pipewire`, `programa.*`, `servi.openssh`, `terminal.*`)

## Secrets

Secrets live in `siri/` and are encrypted with [agenix](https://github.com/ryantm/agenix). Public keys authorized to decrypt them are listed in `siri/secrets.nix`.

Current secrets:

- `portaible-root-password.age`
- `portaible-eter-password.age`

## Usage

Build the `portaible` configuration:

```bash
nixos-rebuild switch --flake .#portaible
```

Build or run the wrapped packages directly:

```bash
nix build .#misuRill
nix build .#misuCanoe
nix build .#misuRiver
nix build .#misuFoot
nix build .#misuFuzzel
nix build .#misuSwaylock
nix build .#misuFish
nix build .#misuNushell
nix run .#misuRiver
```

Update and switch after editing secrets:

```bash
agenix -e siri/secrets.nix
nixos-rebuild switch --flake .#portaible
```

## License

Unlicensed / provided as-is for personal use.
