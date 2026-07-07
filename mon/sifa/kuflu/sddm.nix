{ inputs, ... }:
let
  parseIni = import ./../../../yongu/parseIni.nix { lib = inputs.nixpkgs.lib; };
  defaultSettings = parseIni.parseIni { file = ./faylu/sddm.conf; };
in
{
  flake.nixosModules.sifa.kuflu.sddm =
  { config, lib, ... }:
  let
    opsyon = config.drevosim.kuflu.sddm;
  in
  {
    options.drevosim.kuflu.sddm = {
      enable = lib.mkEnableOption "SDDM display manager" // {
        default = true;
      };
      settings = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = defaultSettings;
        description = "SDDM settings for /etc/sddm.conf.";
      };
    };

    config = lib.mkIf opsyon.enable {
      services.displayManager.sddm = {
        enable = true;
        wayland.enable = true;
        settings = opsyon.settings;
      };
    };
  };
}
