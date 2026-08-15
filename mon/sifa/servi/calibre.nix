{ ... }:
{
  flake.nixosModules.sifa.servi.calibre =
  { config, lib, pkgs, ... }:
  let
    cfg = config.drevosim.servi.calibre;
  in
  {
    options.drevosim.servi.calibre = {
      enable = lib.mkEnableOption "Calibre content server" // {
        default = false;
      };

      host = lib.mkOption {
        type = lib.types.str;
        default = "0.0.0.0";
        description = "Address to bind the Calibre content server to.";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 8080;
        description = "Port to bind the Calibre content server to.";
      };

      openFirewall = lib.mkEnableOption "firewall access to the Calibre content server" // {
        default = true;
      };

      libraryDir = lib.mkOption {
        type = lib.types.str;
        default = "/storage/home/eter/Biblioteca do calibre";
        description = "Calibre library served by the content server. Must match drevosim.medya.calibre.libraryDir.";
      };
    };

    config = lib.mkIf cfg.enable {
      networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];

      systemd.services.calibre-server = {
        description = "Calibre content server";
        after = [ "network.target" "storage.mount" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.calibre}/bin/calibre-server --host ${cfg.host} --port ${toString cfg.port} --with-library ${cfg.libraryDir}";
          Restart = "on-failure";
          RestartSec = "5";

          # Runs as eter so the GUI and the server share the same library
          # and ~/.config/calibre settings without permission juggling.
          User = "eter";
          Group = "users";
          WorkingDirectory = cfg.libraryDir;

          # Hardening
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ReadWritePaths = cfg.libraryDir;
          PrivateTmp = true;
        };
      };
    };
  };
}
