{ self, ... }:
{
  flake.nixosModules.portaibleOgarli =
  { config, ... }:
  {
    drevosim.userName = "eter";

    age.secrets.eter-password = {
      file = self + "/siri/portaible-eter-password.age";
    };

    users.mutableUsers = false;
    users.users.${config.drevosim.userName} = {
      description = "ET";
      hashedPasswordFile = config.age.secrets.eter-password.path;
      isNormalUser = true;
      useDefaultShell = true;
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
    };
  };
}
