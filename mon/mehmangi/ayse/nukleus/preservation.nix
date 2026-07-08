{ ... }:
{
  flake.nixosModules.ayse.nukleus.preservation =
  { ... }:
  {
    systemd.services.systemd-machine-id-commit.enable = false;

    # / lives on a tmpfs, so /home and everything else outside of /persistent
    # is ephemeral. Anything that must survive a reboot has to be preserved
    # explicitly here.
    preservation = {
      enable = true;

      preserveAt."/persistent" = {
        directories = [
          # SSH host keys. Agenix reads these directly from /persistent/etc/ssh
          # as its identity, so this must be preserved.
          "/etc/ssh"

          # Bluetooth pairing keys.
          "/var/lib/bluetooth"

          # Saved Wi-Fi/VPN profiles and connection secrets.
          "/var/lib/NetworkManager/system-connections"

          # NixOS user/group database. Needed early in boot so uids/gids are
          # stable.
          {
            directory = "/var/lib/nixos";
            inInitrd = true;
          }
        ];

        files = [
          # Machine ID. Preserved early so systemd does not regenerate it.
          {
            file = "/etc/machine-id";
            inInitrd = true;
          }
        ];

        # User-specific state. Using the per-user subtree makes preservation
        # create the home directory and preserved paths with eter:users
        # ownership instead of root:root.
        users.eter = {
          directories = [
            # Transitional: broad application and desktop configuration.
            # Includes Chromium, KDE Plasma, and KWallet config. Will be
            # narrowed to specific paths as dotfiles move into Nix.
            ".config"

            # Transitional: broad application data.
            # Includes KWallet data and Plasma state. Will be narrowed later.
            ".local/share"
            ".local/state"

            # SSH user keys and known_hosts.
            ".ssh"

            # Standard XDG user folders.
            "Desktop"
            "Documents"
            "Downloads"
            "Games"
            "Music"
            "Pictures"
            "Public"
            "Templates"
            "Videos"
          ];
        };
      };
    };
  };
}
