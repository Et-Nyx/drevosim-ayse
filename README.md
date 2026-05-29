# Taluji

A modular and highly structured NixOS configuration flake currently managing the `portaible` setup (an external HD install) and designed to scale for future hosts.

---

## System Architecture

The Taluji configuration uses a modular, feature-driven architecture. Rather than maintaining monolithic configuration files for each machine, the system is broken down into granular, reusable modules (features). These features—such as desktop environments, terminal emulators, services, and productivity tools—can be selectively enabled or configured per host. 

Secret management is handled securely via `agenix`, keeping sensitive data like passwords encrypted within the repository.

## Flake Logic (`flake.nix`)

The `flake.nix` file is designed to be exceptionally clean and declarative. It relies on a combination of `flake-parts` and `import-tree` to generate the flake outputs:

1. **`flake-parts`:** Provides a module system for flakes, allowing the configuration to be split across multiple files effortlessly.
2. **`import-tree`:** Automatically traverses the `mon/` directory tree and imports the Nix files found within. 

By passing `inputs.import-tree ./mon` directly into `flake-parts.lib.mkFlake`, the physical folder structure inside `mon/` dynamically defines the entire configuration tree. You do not need to manually manage `imports = [ ... ]` arrays in a central file; adding a new file to the directory tree automatically integrates it into the module system. 

Other notable inputs include `nix-wrapper-modules` for wrapping packages, `nix-maid`, and a non-flake source import for `kwm`.

## Directory Structure

The repository is organized into distinct logical zones. 

```text
Taluji/
├── flake.nix        # Flake inputs and automated output generation
├── README.md        # This file
├── mon/             # Root directory for all system and feature modules
│   ├── mehmangi/    # Host-specific configurations (machines)
│   │   ├── ayse/    # Configuration for a future host
│   │   └── portaible/ # Main portable host (external HD install)
│   │       ├── estandar.nix # Standard options interface to toggle modules
│   │       ├── estrutur.nix # Core system configuration
│   │       ├── hardwer.nix  # Hardware-specific generation and settings
│   │       └── ogarli.nix   # User and home environment definitions
│   └── sifa/        # Reusable feature modules 
│       ├── browsetul/ # Web browsers (e.g., LibreWolf)
│       ├── kolor/     # Theming and color palettes
│       ├── kuflu/     # Display managers / lock screens (e.g., Ly)
│       ├── medya/     # Media tools and players
│       ├── mesa/      # Desktop environments and window managers (River, Niri, Quickshell)
│       ├── produti/   # Productivity software and editors (Neovim, Zed)
│       ├── programa/  # General CLI tools and programs (Git, etc.)
│       ├── servi/     # Background services and daemons (Kanshi)
│       ├── terminal/  # Terminal emulators and shells (Fish, Foot)
│       ├── yongu/     # Utilities and application launchers (Fuzzel)
│       └── yuxi/      # Games and related software
└── siri/            # Secret management
    ├── secrets.nix  # agenix configuration mapping public keys to secrets
    └── *.age        # age-encrypted secret files (passwords, keys)
```

### Breakdown of Key Directories

* **`mon/`**: The core source directory of the configuration. Everything inside this directory is automatically evaluated by `import-tree`.
* **`mon/mehmangi/`**: Contains the specific definitions for individual machines (hosts). For example, the `portaible` directory orchestrates its hardware profile, enables specific features via a standardized options interface, and defines the user environment.
* **`mon/sifa/`**: The library of reusable features. Each subdirectory groups related software or configurations (e.g., desktops, browsers, terminals). This modular approach allows a new host to easily opt-in to a specific set of tools without rewriting configuration logic.
* **`siri/`**: The security enclave of the repository, handling all encrypted variables utilizing `agenix`.
