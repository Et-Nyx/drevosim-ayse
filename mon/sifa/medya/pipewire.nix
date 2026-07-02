{ ... }:
{
  flake.nixosModules.sifa.medya.pipewire =
  { ... }:
  {
    services.pipewire = {
      enable = true;
      pulse.enable = true;
    };
  };
}
