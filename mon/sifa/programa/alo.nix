{ self, inputs, ... }:
{
  flake.nixosModules.alo =
    { pkgs, lib, config, ... }:
    let
      cfg = config.taluji.sifa.programa.alo;
    in
    {
      options.taluji.sifa.programa.alo = {
        enable = lib.mkEnableOption "alo utility utilities";
      };
      config = lib.mkIf cfg.enable {
        environment.systemPackages = with pkgs; [
          wl-clipboard-rs
          tree
        ];
      };
    };
}
