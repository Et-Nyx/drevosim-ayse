{ ... }:
{
  flake.nixosModules.sifa.kuflu.ly =
  { config, lib, ... }:
  {
    options.drevosim.kuflu.ly.enable = lib.mkEnableOption "ly TUI display manager";

    config = lib.mkIf config.drevosim.kuflu.ly.enable {
      services.displayManager.ly.enable = true;
    };
  };
}
