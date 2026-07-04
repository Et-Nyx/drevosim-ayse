{ ... }:
{
  flake.nixosModules.ayse.nukleus.preservation =
  { ... }:
  {
    systemd.services.systemd-machine-id-commit.enable = false;

    # /home is a tmpfs, so anything that must survive a reboot has to be
    # preserved explicitly here.
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
          # Browser profiles and KDE Plasma configuration until they are moved
          # into the Nix expression. Preserving the whole ~/.config keeps
          # Chromium, Ladybird config and Plasma settings in one go.
          "/home/eter/.config"
          "/home/eter/.local/share/Ladybird"
        ];

        files = [
          {
            file = "/etc/machine-id";
            inInitrd = true;
          }
        ];
      };
    };

    # Stale browser lock files survive when the profile is preserved across a
    # reboot. Delete them on every boot so Chromium starts cleanly.
    systemd.tmpfiles.rules = [
      "r /home/eter/.config/chromium/SingletonLock"
      "r /home/eter/.config/chromium/SingletonSocket"
      "r /home/eter/.config/chromium/SingletonCookie"
      # Reset KWallet on every boot so it does not prompt for a password.
      "R /home/eter/.config/kwalletd5"
      "R /home/eter/.local/share/kwalletd"
    ];
  };
}
