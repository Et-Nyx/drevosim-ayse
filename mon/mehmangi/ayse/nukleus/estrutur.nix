{ ... }:
{
  flake.nixosModules.ayse.nukleus.estrutur =
  { ... }:
  {
    networking.hostName = "ayse";

    # Link /etc/nixos to the persistent flake checkout on /home.
    systemd.tmpfiles.rules = [
      "L+ /etc/nixos - - - - /home/eter/nixos"
    ];

    system.stateVersion = "26.05";
  };
}
