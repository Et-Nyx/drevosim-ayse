{ self, inputs, ... }:
{
  flake.nixosModules.neovim =
    { pkgs, lib, config, ... }:
    let
      cfg = config.taluji.sifa.produti.neovim;
      misuNeovim = self.packages.${pkgs.stdenv.hostPlatform.system}.misuNeovim;
    in
    {
      options.taluji.sifa.produti.neovim = {
        enable = lib.mkEnableOption "Custom Neovim configuration";
      };
      config = lib.mkIf cfg.enable {
        programs.neovim = {
          enable = true;
          package = misuNeovim;
        };
      };
    };

  perSystem =
    { pkgs, lib, ... }:
    {
      packages.misuNeovim = inputs.wrapper-modules.wrappers.neovim.wrap {
        inherit pkgs;
        settings = {
          config_directory = ./.;
        };
        specs.basic = {
          data = null;
          before = ["MAIN_INIT"];
          config = /* lua */ ''
            require('init')
          '';
        };
      };
    };
}
