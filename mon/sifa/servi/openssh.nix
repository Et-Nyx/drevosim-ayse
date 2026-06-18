{ ... }:
{
  flake.nixosModules.sifa.servi.openssh =
  {
    services.openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
    };
  };
}
