{ ... }:
{
  flake.nixosModules.ayse.ogarli =
  { config, ... }:
  {
    users.mutableUsers = false;

    users.users.eter = {
      isNormalUser = true;
      hashedPasswordFile = config.age.secrets.ayse-eter-pasalexi.path;
      useDefaultShell = true;
      extraGroups = [
        "wheel"
        "networkmanager"
        "libvirtd"
      ];
      packages = [ ];
    };
  };
}
