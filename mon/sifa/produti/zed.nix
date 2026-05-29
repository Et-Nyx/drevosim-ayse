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
      };
    };
}
