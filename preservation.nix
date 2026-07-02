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

      # /home/eter lives on a separate persistent disk, so it does not need to
      # be preserved here. Add per-user preservation only for paths that live on
      # the ephemeral tmpfs root.
      # users.eter = {
      #   directories = [ ];
      #   files = [ ];
      # };
    };
  };
}
