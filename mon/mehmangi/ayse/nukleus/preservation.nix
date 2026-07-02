{ ... }:
{
  flake.nixosModules.ayse.nukleus.preservation =
  { ... }:
  {
    preservation = {
      enable = true;

      preserveAt."/persistent" = {
        directories = [
          "/etc/ssh"
          "/var/lib/bluetooth"
          "/var/lib/NetworkManager"
          "/var/lib/systemd"
          {
            directory = "/var/lib/nixos";
            inInitrd = true;
          }
        ];

        files = [
          {
            file = "/etc/machine-id";
            inInitrd = true;
          }
        ];
      };
    };
  };
}
