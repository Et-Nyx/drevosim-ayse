{ self, inputs, ... }:
{
  flake.nixosModules.basa =
    { pkgs, lib, config, ... }:
    let
      cfg = config.taluji.sifa.produti.basa;
    in
    {
      options.taluji.sifa.produti.basa = {
        enable = lib.mkEnableOption "Programming Language configurations";
      };
      config = lib.mkIf cfg.enable {
        environment.systemPackages = with pkgs; [
          # Nix
          nil
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
        ];
      };
    };
}
