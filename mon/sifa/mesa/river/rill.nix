{ self, inputs, ... }:
{
  flake.nixosModules.sifa.mesa.rill =
  { pkgs, ... }:
  {
    environment.systemPackages = [
      self.packages.${pkgs.stdenv.hostPlatform.system}.misuRill
    ];
  };

  perSystem =
  { pkgs, self', lib, ... }:
  lib.mkIf pkgs.stdenv.hostPlatform.isLinux
  {
    packages.rill = pkgs.stdenv.mkDerivation {
      pname = "rill";
      version = "0.6.0";
      src = pkgs.fetchFromCodeberg {
        owner = "lzj15";
        repo = "rill";
        rev = "main";
        sha256 = "sha256-sIrzqbTmCbulZgtyY1jD+F/Y0GCp4fL53t1iv0aViiw=";
      };
      nativeBuildInputs = with pkgs; [
        zig
        pkg-config
        wayland-scanner
      ];
      buildInputs = with pkgs; [
        wayland
        wayland-protocols
        libxkbcommon
      ];
      zigBuildFlags = [
        "--system"
        "${pkgs.callPackage "${self}/offolo/rill.nix" {}}"
      ];
      installPhase = ''
        install -Dm755 zig-out/bin/rill $out/bin/rill
      '';
    };
    packages.misuRill = inputs.wrapper-modules.lib.wrapPackage [
      ({ config, lib, wlib, ... }:
      {
        imports = [ wlib.modules.default ];
        options.configPath = lib.mkOption {
          type = lib.types.path;
          description = "Path to the rill config.zon file";
        };
        config = {
          package = self'.packages.rill;
          constructFiles.rill-config = {
            relPath = "config/rill/config.zon";
            content = builtins.readFile config.configPath;
          };
          env.XDG_CONFIG_HOME = "${placeholder "out"}/config";
        };
      })
      {
        inherit pkgs;
        configPath = ./faylu/rill.zon;
      }
    ];
  };
}
