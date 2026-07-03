{ ... }:
{
  flake.nixosModules.ayse.nukleus.estrutur =
  { config, ... }:
  {
    networking.hostName = "ayse";

    # Link /etc/nixos to the persistent flake checkout on /home.
    systemd.tmpfiles.rules = [
      "L+ /etc/nixos - - - - /home/eter/nixos"
    ];

    system.stateVersion = "26.05";

    users.users.root.hashedPasswordFile = config.age.secrets.ayse-root-pasalexi.path;
  };
}
