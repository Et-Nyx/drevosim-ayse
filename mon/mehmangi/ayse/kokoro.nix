{ ... }:
{
  flake.nixosModules.ayse.kokoro =
  { ... }:
  {
    drevosim.servi.kokoro = {
      enable = true;
      # Keep CPU mode as the default. GPU mode can be enabled after confirming
      # the CUDA torch build finishes successfully on this Pascal MX150.
      gpu = true;
    };
  };
}
