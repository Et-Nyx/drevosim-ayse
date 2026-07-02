{ lib, ... }:
{
  flake.nixosModules.sifa.terminal.foot =
  { config, ... }:
  {
    options.drevosim.terminal.foot = {
      enable = lib.mkEnableOption "foot terminal" // {
        default = true;
      };
    };

    config = lib.mkIf config.drevosim.terminal.foot.enable {
      # Real foot config will go here.
    };
  };
}
