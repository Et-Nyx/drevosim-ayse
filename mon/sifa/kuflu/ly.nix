{ lib, ... }:
{
  flake.nixosModules.sifa.kuflu.ly =
  { config, ... }:
  {
    options.drevosim.kuflu.ly = {
      enable = lib.mkEnableOption "ly TUI display manager" // {
        default = false;
      };
    };

    config = lib.mkIf config.drevosim.kuflu.ly.enable {
      # Real ly config will go here.
    };
  };
}
