{ ... }:
{
  flake.nixosModules.sifa.produti.git =
  { config, pkgs, ... }:
  {
    environment.systemPackages = [ pkgs.git ];

    users.users.${config.drevosim.userName}.maid = {
      file.home.".gitconfig".text = ''
        [user]
          name = ET
          email = eter.nyx@proton.me
        [init]
          defaultBranch = master
      '';

      file.home.".ssh/config".text = ''
        Host gitlab.com
          HostName gitlab.com
          User git
          IdentityFile ~/.ssh/id_gitlab
          IdentitiesOnly yes
      '';
    };
  };
}
