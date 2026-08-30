{ ... }:
{
  flake.nixosModules.ayse.nukleus.estrutur =
  { config, ... }:
  {
    networking.hostName = "ayse";

    # The flake checkout lives directly at /etc/nixos (traditional root —
    # no symlink indirection needed).
    systemd.tmpfiles.rules = [
      # HDD storage directories for bulk user data, symlinked to home
      "d /storage/home 0755 root root - -"
      "d /storage/home/eter 0755 eter users - -"
      "d /storage/home/eter/Downloads 0755 eter users - -"
      "d /storage/home/eter/Music 0755 eter users - -"
      "d /storage/home/eter/Videos 0755 eter users - -"

      "L+ /home/eter/Downloads - - - - /storage/home/eter/Downloads"
      "L+ /home/eter/Music - - - - /storage/home/eter/Music"
      "L+ /home/eter/Videos - - - - /storage/home/eter/Videos"
    ];

    system.stateVersion = "26.05";

    users.users.root.hashedPasswordFile = config.age.secrets.ayse-root-pasalexi.path;
  };
}
