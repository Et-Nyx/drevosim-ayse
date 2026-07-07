{ inputs, ... }:
let
  parseIni = import ./../../../yongu/parseIni.nix { lib = inputs.nixpkgs.lib; };
  defaultSettings = parseIni.parseIni { file = ./faylu/foot.ini; flat = false; };

  mkMisuFoot = pkgs: settings: inputs.wrapper-modules.wrappers.foot.wrap {
    inherit pkgs settings;
  };
in
{
  flake.nixosModules.sifa.terminal.foot =
  { config, lib, pkgs, ... }:
  let
    opsyon = config.drevosim.terminal.foot;
  in
  {
    options.drevosim.terminal.foot = {
      enable = lib.mkEnableOption "foot terminal emulator" // {
        default = true;
      };
      settings = lib.mkOption {
        type = lib.types.anything;
        default = defaultSettings;
        description = "Settings for foot.ini";
      };
    };

    config = lib.mkIf opsyon.enable {
      environment.systemPackages = [ (mkMisuFoot pkgs opsyon.settings) ];
    };
  };

  perSystem =
  { pkgs, lib, ... }:
  lib.mkIf pkgs.stdenv.hostPlatform.isLinux
  {
    packages.misuFoot = mkMisuFoot pkgs defaultSettings;
  };
}
