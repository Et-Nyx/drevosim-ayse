{ inputs, ... }:
let
  parseIni = import ./../../../yongu/parseIni.nix { lib = inputs.nixpkgs.lib; };
  defaultSettings = parseIni.parseIni { file = ./faylu/fuzzel.ini; flat = false; };

  mkMisuFuzzel = pkgs: settings: inputs.wrapper-modules.wrappers.fuzzel.wrap {
    inherit pkgs settings;
  };
in
{
  flake.nixosModules.sifa.programa.fuzzel =
  { config, lib, pkgs, ... }:
  let
    cfg = config.drevosim.programa.fuzzel;
  in
  {
    options.drevosim.programa.fuzzel = {
      enable = lib.mkEnableOption "fuzzel application launcher" // {
        default = true;
      };
      settings = lib.mkOption {
        type = lib.types.anything;
        default = defaultSettings;
        description = "Settings for fuzzel.ini";
      };
    };

    config = lib.mkIf cfg.enable {
      environment.systemPackages = [ (mkMisuFuzzel pkgs cfg.settings) ];
    };
  };

  perSystem =
  { pkgs, lib, ... }:
  lib.mkIf pkgs.stdenv.hostPlatform.isLinux
  {
    packages.misuFuzzel = mkMisuFuzzel pkgs defaultSettings;
  };
}
