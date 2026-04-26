{ self, inputs, ... }:
{
  flake.nixosModules.fish =
  { pkgs, lib, ... }:
  {
    programs.fish.enable = true;
    users = {
      defaultUserShell = pkgs.fish;
      users.eter = {
        maid = {
          file.xdg_config."fish/config.fish" = {
            text = /* fish */ ''
              if status is-interactive
              end
            '';
          };
        };
      };
    };
  };
}
