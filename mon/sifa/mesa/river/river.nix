{ ... }:
{
  flake.nixosModules.river =
  { pkgs, lib, config, ... }:
  let
    opsyon = config.drevosim.sifa.mesa.river;
  in
  {
    options.drevosim.sifa.mesa.river = {
      enable = lib.mkEnableOption "River Wayland compositor";
      janela = lib.mkOption {
        type = lib.types.enum [
          "classic"
          "rill"
        ];
        default = "classic";
        description = "River compatible Window Manager";
      };
    };
    config = lib.mkIf opsyon.enable {
      environment.systemPackages =
        if opsyon.janela == "classic"
        then [ pkgs.river-classic ]
        else [ pkgs.river ];
      services.displayManager.defaultSession =
        lib.mkIf (config.services.displayManager.enable or false) "river";
    };
  };
}
