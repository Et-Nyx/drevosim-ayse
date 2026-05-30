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
      environment.systemPackages = with pkgs; [
        zed-editor
      ];
      users.users.${config.taluji.userName}.maid = {
        file.xdg_config."zed/settings.json" = {
          text = builtins.toJSON {
            vim_mode = true;
            format_on_save = "off";

            auto_install_extensions = {
              html = true;
              nix = true;
            };
          };
        };
      };
    };
  };
}
