{ lib, ... }:
{
  options.drevosim.medya.pipewire = {
    enable = lib.mkEnableOption "PipeWire audio stack" // {
      default = true;
    };
  };
}
