{ self, inputs, ... }:
{
  flake.nixosModules.rill =
  { pkgs, ... }:
  {
    environment.systemPackages = [
      self.packages.${pkgs.stdenv.hostPlatform.system}.rill
    ];
  };

  perSystem =
  { pkgs, self', lib, ... }:
  lib.mkIf pkgs.stdenv.hostPlatform.isLinux
  {
    packages.rill = pkgs.stdenv.mkDerivation {
      name = "rill";
      version = "0.5.0";
      src = inputs.rill;
      nativeBuildInputs = with pkgs; [
        zig_0_15
        pkgs-config
        wayland-scanner
      ];
      buildInputs = with pkgs; [
        wayland
        wayland-protocols
      ];
      zigBuildFlags = [
        "--system"
        "${pkgs.callPackage ./build.zid.zon.nix}"
      ];
      installPhase = ''
        install -Dm755 zig-out/bin/rill $out/bin/rill
      '';
    };
    packages.misuRill = inputs.wrapper-modules.lib.wrapperPackage [
      ({ config, lib, wlib, ... }:
      {
        imports = [ wlib.modules.default ];
        options.configPath = lib.mkOption {
          type = lib.types.path;
          description = "Path to the rill config.zon file";
        };
        config.package = self'.packages.rill;
        config.constructFiles.rill-config = {
          relPath = "config/rill/config.zon";
          content = builtins.readFile config.configPath;
        };
      })
      {
        inherit pkgs;
        configPath = ./config.zon;
      }
    ];
  };
}
