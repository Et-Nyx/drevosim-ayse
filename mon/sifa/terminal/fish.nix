{ lib, ... }:
{
  flake.nixosModules.sifa.terminal.fish =
  { config, ... }:
  {
    options.drevosim.terminal.fish = {
      enable = lib.mkEnableOption "fish shell" // {
        default = true;
      };
      defaultUserShell = lib.mkEnableOption "fish as the default user shell";
      shellAliases = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = "Shell aliases for fish.";
      };
    };

    config = lib.mkIf config.drevosim.terminal.fish.enable {
      # Real fish config will go here.
    };
  };
}
