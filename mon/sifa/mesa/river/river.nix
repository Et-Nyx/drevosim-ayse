{ lib, ... }:
{
  options.drevosim.mesa.river = {
    enable = lib.mkEnableOption "river Wayland compositor";
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
}
