{ self, ... }:
{
  flake.nixosModules.portaible.ogarli =
  { config, ... }:
  {
    age.secrets.eter-password = {
      file = self + "/siri/portaible-eter-password.age";
    };

    users.mutableUsers = false;
    users.users.eter = {
      description = "ET";
      hashedPasswordFile = config.age.secrets.eter-password.path;
      isNormalUser = true;
      useDefaultShell = true;
      extraGroups = [
        "networkmanager"
        "wheel"
        "libvirtd"
      ];
    };
  };
}
