{ self, inputs, ... }:
{
  flake.nixosModules.ly =
  { pkgs, lib, ... }:
  {
    services.displayManager.ly = {
      enable = true;
      settings = {
        animation = "matrix";
        hide_borders = false;
      };
    };
  };
}
