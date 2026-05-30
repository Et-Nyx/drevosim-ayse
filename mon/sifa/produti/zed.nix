{ self, inputs, ... }:
{
  flake.nixosModules.zed =
    { pkgs, lib, config, ... }:
    let
      cfg = config.taluji.sifa.produti.zed;
    in
    {
      options.taluji.sifa.produti.zed = {
        enable = lib.mkEnableOption "Zed editor configuration";
      };
      config = lib.mkIf cfg.enable {
        # TODO: Add zed-editor configuration using nix-wrapper-modules or nix-maid
        environment.systemPackages = with pkgs; [
          zed-editor
        ];
        users.users.${config.taluji.userName}.maid = {
          file.xdg_config."zed/settings.json" = {
            text = /* json */ ''
              {
                "vim_mode": true,
                "ui_font_size": 16,
                "buffer_font_size": 16
                }
              }
            '';
          };
        };
      };
    };
}
