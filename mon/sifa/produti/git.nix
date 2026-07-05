{ ... }:
{
  flake.nixosModules.sifa.produti.git =
  { config, lib, pkgs, ... }:
  {
    environment.systemPackages = [ pkgs.git ];

    users.users = lib.mapAttrs
      (user: cfg: {
        maid = {
          file.home.".gitconfig".text = ''
            [user]
              name = ${cfg.name}
              email = ${cfg.email}
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
      })
      config.drevosim.users;
  };
}
