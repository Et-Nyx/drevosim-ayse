{ ... }:
{
  flake.nixosModules.sifa.programa.waydroid =
  { config, lib, ... }:
  let
    cfg = config.drevosim.programa.waydroid;
  in
  {
    options.drevosim.programa.waydroid = {
      enable = lib.mkEnableOption "waydroid virtualization" // {
        default = true;
      };
    };

    config = lib.mkIf cfg.enable {
      virtualisation.waydroid = {
        enable = true;
      };
    };
  };
}
