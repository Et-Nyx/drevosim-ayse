{ ... }:
{
  flake.nixosModules.sifa.kuflu.sddm =
  { config, lib, ... }:
  let
    cfg = config.drevosim.kuflu.sddm;
  in
  {
    options.drevosim.kuflu.sddm = {
      enable = lib.mkEnableOption "SDDM display manager" // {
        default = true;
      };
      theme = lib.mkOption {
        type = lib.types.str;
        default = "breeze";
        description = "SDDM theme to use.";
      };
      settings = lib.mkOption {
        type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
        default = { };
        description = "Extra settings for /etc/sddm.conf.";
      };
    };

    config = lib.mkIf cfg.enable {
      services.displayManager.sddm = {
        enable = true;
        wayland.enable = true;
        inherit (cfg) theme;
        settings = cfg.settings;
      };
    };
  };
}
