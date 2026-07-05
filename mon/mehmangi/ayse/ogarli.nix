{ ... }:
{
  flake.nixosModules.ayse.ogarli =
  { config, ... }:
  {
    security.sudo.wheelNeedsPassword = false;
    users.mutableUsers = false;

    drevosim.users = {
      eter = {
        name = "ET";
        email = "eter.nyx@proton.me";
      };
    };

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
