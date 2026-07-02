{ lib, ... }:
{
  flake.nixosModules.sifa.mesa.river =
  { config, ... }:
  {
    options.drevosim.mesa.river = {
      enable = lib.mkEnableOption "river Wayland compositor" // {
        default = false;
      };
      janela = lib.mkOption {
        type = lib.types.enum [ "rill" "canoe" ];
        default = "canoe";
        description = "Window layout generator to use with river.";
      };
      awto = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra autostart commands specific to river.";
      };
    };

    config = lib.mkIf config.drevosim.mesa.river.enable {
      # Real river config will go here.
    };
  };
}
