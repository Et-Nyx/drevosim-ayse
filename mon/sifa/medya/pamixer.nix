{ self, inputs, ... }:
{
  flake.nixosModules.pamixer =
    { pkgs, lib, config, ... }:
    let
      cfg = config.taluji.sifa.medya.pamixer;
    in
    {
      options.taluji.sifa.medya.pamixer = {
        enable = lib.mkEnableOption "Pamixer PulseAudio/Pipewire CLI mixer";
      };
      config = lib.mkIf cfg.enable {
        environment.systemPackages = [ pkgs.pamixer ];
      };
    };
}
