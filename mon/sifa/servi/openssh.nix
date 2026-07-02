{ lib, ... }:
{
  options.drevosim.servi.openssh = {
    enable = lib.mkEnableOption "OpenSSH daemon" // {
      default = true;
    };
  };
}
