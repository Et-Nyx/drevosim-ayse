{ self, inputs, ... }:
{
  flake.nixosModules.river-classic =
    { pkgs, lib, config, ... }:
    let
      cfg = config.taluji.sifa.mesa.river-classic;
    in
    {
      options.taluji.sifa.mesa.river-classic = {
        enable = lib.mkEnableOption "River classic window manager session";
      };
      config = lib.mkIf cfg.enable {
        programs.river-classic = {
          enable = true;
        };
        users.users.${config.taluji.userName}.maid = {
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
    };
}
