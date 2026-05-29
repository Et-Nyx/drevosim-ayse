{ self, inputs, ... }:
{
  flake.nixosModules.pipewire =
    { pkgs, lib, config, ... }:
    let
      cfg = config.taluji.sifa.medya.pipewire;
    in
    {
      options.taluji.sifa.medya.pipewire = {
        enable = lib.mkEnableOption "PipeWire multimedia system (audio & video)";
      };
      config = lib.mkIf cfg.enable {
        security.rtkit.enable = true;
        services.pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
          jack.enable = true;
        };
      };
    };
}
