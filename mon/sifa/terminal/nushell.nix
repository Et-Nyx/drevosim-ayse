{ lib, ... }:
{
  options.drevosim.terminal.nushell = {
    enable = lib.mkEnableOption "nushell";
    defaultUserShell = lib.mkEnableOption "nushell as the default user shell";
  };
}
