{ ... }:
{
  flake.nixosModules.sifa.servi.openssh =
  { ... }:
  {
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = true;
      };
    };

    networking.firewall.allowedTCPPorts = [ 22 ];
  };
}
