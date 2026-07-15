{ ... }:
{
  flake.nixosModules.sifa.servi.ftp-ps4 =
  { config, lib, pkgs, ... }:
  let
    cfg = config.drevosim.servi.ftp-ps4;
    remoteName = "ps4-ftp";
  in
  {
    options.drevosim.servi.ftp-ps4 = {
      enable = lib.mkEnableOption "PS4 FTP filesystem mount via rclone (FUSE, on-demand)";

      host = lib.mkOption {
        type = lib.types.str;
        default = "192.168.15.200";
        description = "PS4 FTP server hostname or IP address.";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 2121;
        description = "PS4 FTP server port.";
      };

      mountPoint = lib.mkOption {
        type = lib.types.str;
        default = "/mnt/ps4";
        description = "Local directory where the PS4 FTP filesystem is mounted.";
      };

      user = lib.mkOption {
        type = lib.types.str;
        default = "anonymous";
        description = "FTP username. PS4 homebrew FTP servers usually accept 'anonymous' with any password.";
      };

      readOnly = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Mount the PS4 filesystem read-only.";
      };

      idleTimeoutSec = lib.mkOption {
        type = lib.types.ints.positive;
        default = 300;
        description = "Seconds of inactivity before the on-demand mount is automatically unmounted.";
      };
    };

    config = lib.mkIf cfg.enable (let
      # rclone's FTP backend decodes ALL password sources (config file,
      # environment variable, command line) as base64-obscured strings.
      # Plain-text passwords are rejected with a base64 decode error.
      #
      # We therefore pass the password via RCLONE_FTP_PASS, but the value
      # must itself be the obscured form. We generate it at build time by
      # running `rclone obscure` on the plaintext through the SAME rclone
      # derivation that will be installed at runtime (pkgs.rclone, from
      # the locked nixpkgs). This keeps the obscured string in sync with
      # the running rclone version as long as the flake lock is not
      # updated.
      obscuredPass = builtins.readFile (
        pkgs.runCommand "rclone-ps4-obscure" { } ''
          ${pkgs.rclone}/bin/rclone obscure 'anonymous@' > $out
        ''
      );
    in {
      environment.systemPackages = [ pkgs.rclone ];

      # Required for the 'allow-other' FUSE option used by rclone, so that
      # non-root users (e.g. the desktop user running the file manager) can
      # browse the mount.
      programs.fuse.userAllowOther = true;

      # The mount point and rclone cache live on the ephemeral root. This is
      # intentional: the mount itself is recreated on access, and the cache is
      # just a performance hint that does not need to survive reboots. The
      # actual data stays on the PS4.
      systemd.tmpfiles.rules = [
        "d ${cfg.mountPoint} 0755 root root - -"
        "d /var/cache/rclone-ps4 0755 root root - -"
      ];

      # rclone configuration. The FTP backend supports anonymous login; we
      # use the standard 'anonymous@' password placeholder, which is what
      # GoldHEN and most other PS4 homebrew FTP servers expect. The password
      # itself is supplied at runtime via the RCLONE_FTP_PASS environment
      # variable (see the wrapper below) in its obscured form, generated
      # at build time (see `obscuredPass` binding above).
      environment.etc."rclone-ps4.conf".text = ''
        [${remoteName}]
        type = ftp
        host = ${cfg.host}
        port = ${toString cfg.port}
        user = ${cfg.user}
        no_check_certificate = true
        disable_utf8 = false
      '';

      # Wrapper script invoked by systemd as the FUSE binary. It receives
      # the mountpoint as $1 and ignores any further FUSE options, applying
      # our own rclone options instead.
      environment.etc."rclone-ps4-mount".source =
        pkgs.writeShellScript "rclone-ps4-mount" ''
          set -eu
          MOUNTPOINT="''${1:-}"
          if [ -z "$MOUNTPOINT" ]; then
            echo "rclone-ps4-mount: missing mountpoint argument" >&2
            exit 1
          fi
          shift
          export RCLONE_FTP_PASS='${obscuredPass}'
          exec ${pkgs.rclone}/bin/rclone mount \
            --config=/etc/rclone-ps4.conf \
            --cache-dir=/var/cache/rclone-ps4 \
            --vfs-cache-mode=full \
            --vfs-cache-poll-interval=30s \
            --dir-cache-time=30m \
            --poll-interval=30s \
            --allow-other \
            --timeout=10s \
            --contimeout=10s \
            ${lib.optionalString cfg.readOnly "--read-only"} \
            ${remoteName}: "$MOUNTPOINT"
        '';

      # On-demand FUSE mount, implemented as a systemd service rather than
      # a mount unit. systemd-fstab-generated mount units for FUSE don't
      # work well with rclone: rclone runs in the foreground and never
      # notifies readiness, so the default 90s TimeoutStartSec kills it
      # before the user can browse.
      #
      # The service starts at boot and tries to mount. If the PS4 is
      # offline, rclone fails and systemd restarts it every 30 seconds.
      # When the PS4 comes online, the next retry succeeds. The mount
      # stays up as long as the PS4 is reachable. There is no idle
      # unmount — once mounted, it stays mounted until the PS4
      # disconnects or the system shuts down.
      systemd.services."rclone-ps4" = {
        description = "PS4 FTP mount (rclone FUSE)";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "/etc/rclone-ps4-mount ${cfg.mountPoint}";
          ExecStop = "/bin/fusermount3 -u ${cfg.mountPoint}";
          Restart = "on-failure";
          RestartSec = "30s";
        };
      };
    });
  };
}
