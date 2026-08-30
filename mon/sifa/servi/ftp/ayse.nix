{ ... }:
{
  flake.nixosModules.sifa.servi.ftp-ayse =
  { config, lib, ... }:
  let
    cfg = config.drevosim.servi.ftp-ayse;
  in
  {
    options.drevosim.servi.ftp-ayse = {
      enable = lib.mkEnableOption "anonymous FTP server" // {
        default = false;
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 21;
        description = "Port to bind the FTP control connection to.";
      };

      passiveMinPort = lib.mkOption {
        type = lib.types.port;
        default = 30000;
        description = "Minimum passive-mode data port.";
      };

      passiveMaxPort = lib.mkOption {
        type = lib.types.port;
        default = 30100;
        description = "Maximum passive-mode data port.";
      };

      openFirewall = lib.mkEnableOption "firewall access to the FTP server" // {
        default = true;
      };

      stateDir = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/ftp-srv";
        readOnly = true;
        description = "Runtime root directory for anonymous FTP. Uploads are written to the 'upload' subdirectory.";
      };
    };

    config = lib.mkIf cfg.enable {
      services.vsftpd = {
        enable = true;

        # Anonymous, password-less access. This matches the expectation of
        # console homebrew FTP clients (PS4-style) that just want to dump or
        # pull files without entering credentials.
        anonymousUser = true;
        anonymousUserNoPassword = true;
        anonymousUploadEnable = true;
        anonymousMkdirEnable = true;
        anonymousUmask = "022";
        writeEnable = true;
        anonymousUserHome = cfg.stateDir;

        extraConfig = ''
          # Passive mode ports and control port.
          listen_port=${toString cfg.port}
          pasv_min_port=${toString cfg.passiveMinPort}
          pasv_max_port=${toString cfg.passiveMaxPort}

          # Allow anonymous users to rename/delete inside writable areas.
          anon_other_write_enable=YES

          # Reasonable connection limits for a home setup.
          max_clients=200
          max_per_ip=50
          idle_session_timeout=300
          data_connection_timeout=300
        '';
      };

      # The upstream vsftpd module creates the anonymous root with mode 0555
      # owned by ftp:ftp, which prevents the anonymous user from traversing
      # it. We only need to ensure the root is widened to 0755 root:ftp and
      # that the writable 'upload' subdirectory exists with the right
      # ownership.
      #
      # Note: a 'Z' (recursive) rule on the parent would force the upload
      # subdirectory to root:ftp, which would break anonymous writes, so
      # we use 'd' (single directory) here.
      systemd.tmpfiles.rules = lib.mkAfter [
        # Non-recursive ('z'): widen only the anonymous root itself so the
        # anonymous user can traverse it.
        "z ${cfg.stateDir} 0755 root ftp - -"
        "d ${cfg.stateDir}/upload 0755 ftp ftp - -"
      ];

      networking.firewall = lib.mkIf cfg.openFirewall {
        allowedTCPPorts = [ cfg.port ];
        allowedTCPPortRanges = [{
          from = cfg.passiveMinPort;
          to = cfg.passiveMaxPort;
        }];
      };
    };
  };
}
