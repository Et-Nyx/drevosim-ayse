# Drevosim

A dendritic NixOS configuration with standalone home-manager dotfiles, built on [flake-parts](https://github.com/hercules-ci/flake-parts), [import-tree](https://github.com/vic/import-tree), [nix-wrapper-modules](https://github.com/BirdeeHub/nix-wrapper-modules), and [nix-maid](https://github.com/viperML/nix-maid).

The layout branches like a tree: a single flake root feeds a trunk of module directories, which split into hosts and features, which split again into smaller, composable units.

## Layout

```text
.
├── flake.nix      # flake definition
├── mon/           # module tree
│   ├── parts.nix  # flake-parts configuration
│   ├── mehmangi/  # host machines
│   │   ├── ayse/
│   │   └── portaible/
│   └── sifa/      # feature modules
│       ├── kolor/     # customization
│       ├── kuflu/     # security & login
│       ├── medya/     # media programs
│       ├── mesa/      # window managers & compositors
│       ├── produti/   # productivity tools
│       ├── programa/  # general programs
│       ├── servi/     # services
│       ├── terminal/  # console tools
│       └── yuxi/      # gaming packages
└── siri/          # secrets managed by agenix
```

## Naming

Most directory and file names use a small project-specific vocabulary instead of plain English:

| Term | Meaning |
|------|---------|
| `mon` | modules (the whole module tree) |
| `mehmangi` | machines / hosts |
| `sifa` | features / capabilities |
| `siri` | secrets |
| `ayse` | (reserved for additional hosts) |
| `portaible` | portable NixOS host |
| `estandar` | standard / base host configuration |
| `estrutur` | structure / system structure |
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

## Flake inputs

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.05";
    nix-maid.url = "github:viperML/nix-maid";
    import-tree.url = "github:vic/import-tree";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    wrapper-modules = {
      url = "github:BirdeeHub/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake
    { inherit inputs; }
    (inputs.import-tree ./mon);
}
```

`import-tree ./mon` recursively imports the entire `mon/` directory as flake-parts modules, so adding a new file under `mon/mehmangi/` or `mon/sifa/` automatically becomes part of the flake outputs.

## Hosts

The only host defined so far is `portaible`. It is assembled in `mon/mehmangi/portaible/estandar.nix` from:

- `nix-maid.nixosModules.default` — home-manager style user setup
- `agenix.nixosModules.default` — secret decryption
- `self.nixosModules.portaibleEstrutur` — base system config
- `self.nixosModules.portaibleOgarli` — user config
- `self.nixosModules.monEstandar` — shared defaults (default username, etc.)
- `self.nixosModules.portaibleHardwer` — hardware configuration

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

Update and switch after editing secrets:

```bash
agenix -e siri/secrets.nix
nixos-rebuild switch --flake .#portaible
```

## License

Unlicensed / provided as-is for personal use.
