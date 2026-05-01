{ self, inputs, ...}:
{
  flake.nixosModules.alo =
  { pkgs, ... }:
  {
    environment.systemPackages = with pkgs;[
      wl-clipboard-rs
    ];
  };
}
