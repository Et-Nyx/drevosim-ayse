{ inputs, ... }:
let
  parseIni = import ./../../../yongu/parseIni.nix { lib = inputs.nixpkgs.lib; };
  defaultSettings = parseIni.parseIni { file = ./faylu/ly.ini; flat = true; };
in
{
  flake.nixosModules.sifa.kuflu.ly =
  { config, lib, ... }:
  let
    opsyon = config.drevosim.kuflu.ly;
  in
  {
    options.drevosim.kuflu.ly = {
      enable = lib.mkEnableOption "ly TUI display manager" // {
        default = false;
      };
      settings = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = defaultSettings;
        description = "ly settings for /etc/ly/config.ini";
      };
    };

    config = lib.mkIf opsyon.enable {
      services.displayManager.ly = {
        enable = true;
        settings = opsyon.settings;
      };
    };
  };
}
