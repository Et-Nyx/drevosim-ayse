{ ... }:
{
  flake.nixosModules.sifa.basa =
  { pkgs, ... }:
  {
    environment.systemPackages = with pkgs; [
    # Nix
    nil
    nixd
    nixpkgs-fmt

    # Zig
    zig
    zls

    # Lua
    lua
    lua-language-server

    # C/Base
    gcc
    gnumake
    pkg-config

    # Rust
    rustc
    cargo
    rust-analyzer

    # Python
    python3
    basedpyright
    ruff

    # Java
    jdk
    jdt-language-server

    # JSON
    package-version-server
    ];
  };
}
