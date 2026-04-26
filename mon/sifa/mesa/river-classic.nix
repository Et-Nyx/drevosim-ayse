{ self, inputs, ... }:
{
  flake.nixosModules.river-classic =
  { pkgs, lib, ... }:
  {
   programs.river-classic = {
      enable = true;
    };
    users.users.eter.maid = {
      file.xdg_config."river/init" = {
        text = /* sh */ ''
          #!/bin/sh
          riverctl map normal Super Return spawn foot
          riverctl map normal Super Q close
          riverctl map normal Super Escape exit
        '';
        executable = true;
      };
    };
  };
}
