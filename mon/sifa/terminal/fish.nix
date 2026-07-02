{ lib, ... }:
{
  options.drevosim.terminal.fish = {
    enable = lib.mkEnableOption "fish shell";
    defaultUserShell = lib.mkEnableOption "fish as the default user shell";
    shellAliases = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Shell aliases for fish.";
    };
  };
}
