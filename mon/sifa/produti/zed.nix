{ self, inputs, ... }:
{
  flake.nixosModules.zed =
  { pkgs, ... }:
  {
    # TODO: Add zed-editor configuration using nix-wrapper-modules or nix-maid
  };
}
