# Drevosim

A dendritic NixOS configuration with homeless dotfiles, built on [flake-parts](https://github.com/hercules-ci/flake-parts), [import-tree](https://github.com/vic/import-tree), [nix-wrapper-modules](https://github.com/BirdeeHub/nix-wrapper-modules), and [nix-maid](https://github.com/viperML/nix-maid).

The layout branches like a tree: a single flake root feeds a trunk of module directories, which split into hosts, features, helpers, and secrets.

## Layout

```text
.
├── flake.nix         # flake definition
├── mon/              # module tree (imported recursively by import-tree)
│   ├── parts.nix     # flake-parts configuration + shared options
│   ├── mehmangi/     # host machines
│   │   └── portaible/
│   │       ├── estandar.nix   # host assembler
│   │       ├── estrutur.nix   # base system config
│   │       ├── hardwer.nix    # hardware config
│   │       └── ogarli.nix     # user config
│   └── sifa/         # feature modules
│       └── mesa/     # window managers & compositors
│           └── river/
│               ├── river.nix   # river wrapper module
│               ├── rill.nix    # rill wrapper module
│               └── faylu/      # rill configuration files
│                   └── rill.zon
├── offolo/           # offline / external build dependencies
│   └── rill.nix      # zig dependencies for rill
├── yongu/            # helper functions
│   └── monlari.nix   # recursive NixOS module collector
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
| `kolor` | theming & customization |
| `kuflu` | security & login |
| `medya` | media |
| `mesa` | window managers & compositors |
| `produti` | productivity |
| `programa` | general programs |
| `servi` | services |
| `terminal` | terminal/console tools |
| `yuxi` | gaming |
| `offolo` | offline / external build dependencies |
| `yongu` | helper functions |
| `monlari` | recursive module collector |
| `faylu` | configuration files |
| `misuRill` | wrapped rill package |
| `misuRiver` | wrapped river package |

## How modules are loaded

`import-tree ./mon` recursively imports every `.nix` file under `mon/` as a flake-parts module. Each module can export `flake.nixosModules.<path>`.

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

## Wrapper modules

The project uses nix-wrapper-modules to create homeless, store-path-based configurations for programs. Each wrapper sets `XDG_CONFIG_HOME` to a generated directory inside the Nix store, so the programs read their configs from there instead of from `~/.config`.

### Rill

`mon/sifa/mesa/river/rill.nix` packages and wraps [rill](https://codeberg.org/lzj15/rill), a scrolling window manager for river. Because rill is not in nixpkgs, it is built from source with `pkgs.fetchFromCodeberg`. Its Zig dependencies are vendored in `offolo/rill.nix`.

The wrapped package is `.#misuRill`. It bakes `mon/sifa/mesa/river/faylu/rill.zon` into the store and sets `XDG_CONFIG_HOME` so rill finds its config.

### River

`mon/sifa/mesa/river/river.nix` wraps the [river](https://codeberg.org/river/river) Wayland compositor. The wrapper generates `river/init`, which execs the wrapped rill, and sets `XDG_CONFIG_HOME` so river finds its init file.

The wrapped package is `.#misuRiver`.

## Hosts

The only host defined so far is `portaible`. It is assembled automatically from:

- `inputs.nix-maid.nixosModules.default` — nix-maid user environment
- `inputs.agenix.nixosModules.default` — secret decryption
- `self.nixosModules.basi` — shared options (`drevosim.userName`)
- `self.nixosModules.portaible.*` — host-specific modules (`estrutur`, `hardwer`, `ogarli`)
- `self.nixosModules.sifa.*` — feature modules (`mesa.river`, `mesa.rill`)

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
nix build .#misuRiver
nix run .#misuRiver
```

Update and switch after editing secrets:

```bash
agenix -e siri/secrets.nix
nixos-rebuild switch --flake .#portaible
```

## License

Unlicensed / provided as-is for personal use.
