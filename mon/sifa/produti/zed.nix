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
            lsp = {
              package-version-server = {
                binary = {
                  path = "package-version-server";
                };
              };
            };
            vim_mode = true;
            format_on_save = "off";
            theme = {
              mode = "dark";
              dark = "Zedwaita Dark";
              light = "Zedwaita Light";
            };
            icon_theme = {
              mode = "dark";
              dark = "Colored Zed Icons Theme Dark";
              light = "Colored Zed Icons Theme White";
            };

            auto_install_extensions = {
              html = true;
              nix = true;
              rust = true;
              haskell = true;
              zig = true;
              lua = true;
              fish = true;
              git-firefly = true;

              zedwaita = true;
              colored-zed-icons-theme = true;
            };
          };
        };
      };
    };
  };
}
