{ inputs, ... }:
let
  parseIni = import ./../../../yongu/parseIni.nix { lib = inputs.nixpkgs.lib; };
  defaultSettings = parseIni.parseIni { file = ./faylu/mako.ini; flat = false; };

  mkMisuMako = pkgs: settings: inputs.wrapper-modules.wrappers.mako.wrap {
    inherit pkgs settings;
  };
in
{
  flake.nixosModules.sifa.servi.mako =
  { config, lib, pkgs, ... }:
  let
    opsyon = config.drevosim.servi.mako;
  in
  {
    options.drevosim.servi.mako = {
      enable = lib.mkEnableOption "mako notification daemon" // {
        default = true;
      };
      settings = lib.mkOption {
        type = lib.types.anything;
        default = defaultSettings;
        description = "Settings for mako config";
      };
    };

    config = lib.mkIf opsyon.enable {
      environment.systemPackages = [ (mkMisuMako pkgs opsyon.settings) ];
      drevosim.xorawto = [ "mako" ];
    };
  };

  perSystem =
  { pkgs, lib, ... }:
  lib.mkIf pkgs.stdenv.hostPlatform.isLinux
  {
    packages.misuMako = mkMisuMako pkgs defaultSettings;
  };
}
