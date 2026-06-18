{ ... }:
{
  flake.nixosModules.sifa.medya.pipewire =
  { pkgs, ... }:
  {
    # PipeWire replaces PulseAudio as the system audio server.
    # Explicitly disable the legacy PulseAudio service to avoid conflicts.
    services.pulseaudio.enable = false;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    services.pipewire.wireplumber.enable = true;

    environment.systemPackages = [ pkgs.pamixer ];
  };
}
