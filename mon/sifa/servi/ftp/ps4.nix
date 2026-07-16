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

      # --- Connection / FTP-backend tunables ---

      disableEpsv = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Disable Extended Passive Mode (EPSV) and force plain PASV.
          PS4 GoldHEN's EPSV implementation is buggy and often produces
          unusable data-port allocations; PASV is more reliable.
        '';
      };

      disableMlsd = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Disable MLSD and force plain LIST for directory listings.
          The PS4's MLSD responses are inconsistent (truncated or
          misformatted); plain LIST is universally supported and
          faster on this target.
        '';
      };

      ftpConcurrency = lib.mkOption {
        type = lib.types.ints.unsigned;
        default = 1;
        description = ''
          Maximum number of FTP control connections per backend.
          The PS4 FTP server is single-threaded; >1 corrupts listings.
        '';
      };

      # --- Mount / VFS tunables ---

      timeout = lib.mkOption {
        type = lib.types.str;
        default = "30s";
        description = "Per-FTP-command timeout.";
      };

      contimeout = lib.mkOption {
        type = lib.types.str;
        default = "30s";
        description = "FTP control-connection timeout.";
      };

      bufferSize = lib.mkOption {
        type = lib.types.str;
        default = "64Mi";
        description = ''
          In-memory read buffer per open file. Larger = smoother
          large-file copies, at the cost of RAM (per open file).
        '';
      };

      vfsReadAhead = lib.mkOption {
        type = lib.types.str;
        default = "128Mi";
        description = ''
          Extra disk-buffered read ahead when --vfs-cache-mode=full.
          Increases sequential-read throughput for large files.
        '';
      };

      transfers = lib.mkOption {
        type = lib.types.ints.unsigned;
        default = 4;
        description = "Parallel file transfers when uploading from the VFS cache.";
      };

      checkers = lib.mkOption {
        type = lib.types.ints.unsigned;
        default = 8;
        description = "Parallel directory scans against the FTP backend.";
      };

      lowLevelRetries = lib.mkOption {
        type = lib.types.ints.unsigned;
        default = 20;
        description = ''
          Number of low-level (FTP-command-level) retries before
          giving up. Higher than the default (10) so a flaky PS4
          doesn't drop the whole mount session.
        '';
      };

      dirCacheTime = lib.mkOption {
        type = lib.types.str;
        default = "2m";
        description = ''
          How long directory listings are cached before being
          re-fetched. Lower = more accurate sync; higher = fewer
          FTP LIST commands.
        '';
      };

      pollInterval = lib.mkOption {
        type = lib.types.str;
        default = "10s";
        description = "How often the FTP backend polls for changes (must be < dirCacheTime).";
      };

      vfsCacheMode = lib.mkOption {
        type = lib.types.enum [ "off" "minimal" "writes" "full" ];
        default = "writes";
        description = ''
          rclone VFS cache mode.
          - "writes": caches pending writes until uploaded, does NOT
            prefetch reads. Recommended for the PS4: no cache bloat
            from browsing, and pending writes are cached on the SSD
            subvolume (see gida/ssd-cache.md).
          - "minimal": like "writes" but evicts the cache entry as
            soon as the upload completes. More space-efficient, but
            no resume on transient FTP hiccups.
          - "full": caches reads too. Fast for repeated reads of the
            same file, but fills the cache quickly with browsing data.
          - "off": no caching. Every read and write goes straight to
            the PS4. Slowest.
        '';
      };

      vfsCacheMaxSize = lib.mkOption {
        type = lib.types.str;
        default = "10G";
        description = ''
          Maximum size of the VFS cache directory. Since the cache
          lives on the SSD subvolume (/mnt/ssd/cache/rclone-ps4/),
          this is mostly a soft cap to prevent runaway growth. The
          4 GB tmpfs root no longer limits us.
        '';
      };

      vfsCachePollInterval = lib.mkOption {
        type = lib.types.str;
        default = "5s";
        description = ''
          How often the VFS layer polls the backend to detect file
          changes. Lower = more accurate sync, more FTP traffic.
        '';
      };

      attrTimeout = lib.mkOption {
        type = lib.types.str;
        default = "5s";
        description = ''
          Kernel-side attribute cache TTL. Lower = more up-to-date
          size/mtime in the file manager; higher = fewer STAT calls.
        '';
      };

      noChecksum = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Skip MD5 computation on every transfer. TCP checksums
          already catch bit errors on a LAN. Disabling this
          noticeably speeds up large transfers.
        '';
      };

      logFile = lib.mkOption {
        type = lib.types.str;
        default = "/var/log/rclone-ps4.log";
        description = ''
          Path to the rclone log file. Empty string disables
          file logging (rclone still logs to journald).
        '';
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

      # The mount point lives on the ephemeral root (FUSE will overlay it
      # at runtime). The VFS cache lives on the SSD subvolume
      # /mnt/ssd/cache/rclone-ps4/ — see gida/ssd-cache.md. This is
      # critical for large-file copies: the 4 GB tmpfs root can't hold a
      # multi-gigabyte .pkg mid-transfer, but the SSD subvolume can.
      #
      # We don't create /mnt/ssd/cache itself here — disko mounts it.
      # We just create the service's subdirectory under it.
      systemd.tmpfiles.rules = [
        "d ${cfg.mountPoint} 0755 root root - -"
        "d /mnt/ssd/cache/rclone-ps4 0755 root root - -"
      ] ++ lib.optionals (cfg.logFile != "") [
        # rclone log file. Ephemeral (lives on the tmpfs root) — journald
        # is the persistent record. The `f` ensures the file exists with
        # the right ownership so rclone can write to it on first start.
        "f ${cfg.logFile} 0644 root root - -"
      ];

      # rclone configuration. The FTP backend supports anonymous login; we
      # use the standard 'anonymous@' password placeholder, which is what
      # GoldHEN and most other PS4 homebrew FTP servers expect. The password
      # itself is supplied at runtime via the RCLONE_FTP_PASS environment
      # variable (see the wrapper below) in its obscured form, generated
      # at build time (see `obscuredPass` binding above).
      #
      # The PS4 FTP server (GoldHEN) is a minimal implementation with
      # known issues around EPSV and MLSD. We force plain PASV and plain
      # LIST for maximum stability and accurate listings.
      environment.etc."rclone-ps4.conf".text = ''
        [${remoteName}]
        type = ftp
        host = ${cfg.host}
        port = ${toString cfg.port}
        user = ${cfg.user}
        no_check_certificate = true
        disable_utf8 = false
        ${lib.optionalString cfg.disableEpsv "disable_epsv = true"}
        ${lib.optionalString cfg.disableMlsd "disable_mlsd = true"}
        concurrency = ${toString cfg.ftpConcurrency}
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
            --cache-dir=/mnt/ssd/cache/rclone-ps4 \
            --vfs-cache-mode=${cfg.vfsCacheMode} \
            --vfs-cache-poll-interval=${cfg.vfsCachePollInterval} \
            --vfs-cache-max-size=${cfg.vfsCacheMaxSize} \
            --vfs-cache-max-age=24h \
            --vfs-read-ahead=${cfg.vfsReadAhead} \
            --dir-cache-time=${cfg.dirCacheTime} \
            --attr-timeout=${cfg.attrTimeout} \
            --buffer-size=${cfg.bufferSize} \
            --transfers=${toString cfg.transfers} \
            --checkers=${toString cfg.checkers} \
            --low-level-retries=${toString cfg.lowLevelRetries} \
            --timeout=${cfg.timeout} \
            --contimeout=${cfg.contimeout} \
            ${lib.optionalString cfg.noChecksum "--no-checksum"} \
            ${lib.optionalString (cfg.logFile != "") "--log-file=${cfg.logFile}"} \
            ${lib.optionalString (cfg.logFile != "") "--log-level=INFO"} \
            --allow-other \
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
      #
      # Self-healing: ExecStartPre cleans up any stale FUSE mount left
      # over from a previous crash. The previous /bin/fusermount3 path
      # did not exist on NixOS, so ExecStop never actually unmounted;
      # that left the FUSE entry stuck in the kernel and caused a crash
      # loop on every restart. We now use the absolute path from the
      # fuse3 package and run the unmount both before start and on stop.
      systemd.services."rclone-ps4" = {
        description = "PS4 FTP mount (rclone FUSE)";
        # Wait for the SSD cache subvolume to be mounted before starting.
        # The rclone VFS cache directory (/mnt/ssd/cache/rclone-ps4)
        # is on the @cache btrfs subvolume; if the service starts
        # before the mount is ready, rclone creates the directory on
        # the tmpfs root (which then fills up, as we discovered).
        #
        # Note: the mount unit is named "mnt-ssd-cache.mount" with a
        # LITERAL dash. The \x2d escape is only for the directive value
        # syntax, not the unit name on disk. The actual generator file
        # at /run/systemd/generator/mnt-ssd-cache.mount confirms this.
        after = [
          "network-online.target"
          "mnt-ssd-cache.mount"
        ];
        wants = [ "network-online.target" ];
        requires = [ "mnt-ssd-cache.mount" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "simple";
          # Explicit /bin/sh -c so the `|| true` is handled by the shell.
          # Without it, systemd on this host passes the whole command line
          # as args to fusermount3 (the `|` metacharacter detection does
          # not fire here), and fusermount3 fails with "extra arguments
          # after the mountpoint".
          ExecStartPre = "/bin/sh -c '${lib.getBin pkgs.fuse3}/bin/fusermount3 -u ${cfg.mountPoint} || true'";
          ExecStart = "/etc/rclone-ps4-mount ${cfg.mountPoint}";
          ExecStop = "/bin/sh -c '${lib.getBin pkgs.fuse3}/bin/fusermount3 -u ${cfg.mountPoint} || true'";
          Restart = "on-failure";
          RestartSec = "30s";
          # Note: we deliberately do NOT add `ProtectSystem=strict` /
          # `ReadWritePaths` here. The FUSE mount operation interacts
          # poorly with that hardening on this host: the mount fails
          # with "directory already mounted" even when no mount exists
          # (the kernel's mount-namespace check sees the restricted
          # namespace). Running the service without those restrictions
          # is safe because rclone talks only to the configured FTP
          # endpoint and the configured mount/cache/log paths.
        };
      };
    });
  };
}
