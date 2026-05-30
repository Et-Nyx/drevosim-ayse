{ self, inputs, ... }:
{
  flake.nixosModules.portaibleOgarli =
  { pkgs, config, ... }:
  {
    taluji.userName = "eter";

    age.secrets.eter-password = {
      file = self + "/siri/portaible-eter-password.age";
    };

    users.mutableUsers = false;
    users.users.${config.taluji.userName} = {
      description = "ET";
      hashedPasswordFile = config.age.secrets.eter-password.path;
      isNormalUser = true;
      useDefaultShell = true;
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
      maid = {
        systemd.globalEnvironment = {
          XDG_CURRENT_DESKTOP = "river";
          EDITOR = "nvim";
        };
      };
    };
    programs.ssh.extraConfig = /* bash */ ''
      Host gitlab.com
      User git
      IdentityFile ~/.ssh/gitlab/gitlab_ed25519
    '';
  };
}
