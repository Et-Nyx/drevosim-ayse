{ self, inputs, ... }:
{
  flake.nixosModules.portaibleOgarli =
  { pkgs, ... }:
  {
    users.mutableUsers = false;
    users.users.eter = {
      description = "ET";
      hashedPassword = "REDACTED";
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
    programs.ssh.extraConfig = ''
      Host gitlab.com
      User git
      IdentityFile ~/.ssh/gitlab/gitlab_ed25519
    '';
  };
}
