{ lib, ... }:
{
  flake.nixosModules.sifa.terminal.nushell =
  { config, ... }:
  {
    options.drevosim.terminal.nushell = {
      enable = lib.mkEnableOption "nushell" // {
        default = true;
      };
      defaultUserShell = lib.mkEnableOption "nushell as the default user shell";
    };

    config = lib.mkIf config.drevosim.terminal.nushell.enable {
      # Real nushell config will go here.
    };
  };
}
