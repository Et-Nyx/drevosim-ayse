{ ... }:
{
  flake.nixosModules.sifa.servi.tailscale =
  { config, lib, pkgs, ... }:
  let
    cfg = config.drevosim.servi.tailscale;
  in
  {
    options.drevosim.servi.tailscale = {
      enable = lib.mkEnableOption "Tailscale" // {
        default = true;
      };
      authKeyFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = config.age.secrets.ayse-tailscale-auth.path or null;
        description = "File containing the Tailscale auth key (agenix-managed).";
      };
      ports = lib.mkOption {
        type = lib.types.listOf lib.types.port;
        default = [ 8000 8880 ];
        description = "TCP ports opened on the tailscale0 interface only.";
      };
      serve = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {
          "8000" = "127.0.0.1:8000"; # SillyTavern
          "8880" = "127.0.0.1:8880"; # Kokoro TTS API
        };
        description = ''
          Tailscale Serve routes: HTTPS port on the tailnet hostname -> local backend.
          Each entry yields https://ayse.<tailnet>.ts.net:<port> proxying to the
          given local address with a valid Tailscale-issued certificate.
          Set to { } to disable Serve entirely.
        '';
      };
    };

    config = lib.mkIf cfg.enable {
      services.tailscale = {
        enable = true;
        openFirewall = true;
        authKeyFile = cfg.authKeyFile;
      };

      # Web services reachable ONLY over the tailnet; MagicDNS gives them
      # https://ayse.<tailnet>.ts.net:<port> URLs from the phone.
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = cfg.ports;

      # Apply Tailscale Serve routes on boot so HTTPS keeps working even after
      # the daemon state is reset. Serve config itself lives in /var/lib/tailscale.
      systemd.services.tailscale-serve = lib.mkIf (cfg.serve != { }) {
        wantedBy = [ "multi-user.target" ];
        after = [ "tailscaled.service" ];
        wants = [ "tailscaled.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "tailscale-serve" ''
            set -euo pipefail
            ${lib.concatStringsSep "\n" (lib.mapAttrsToList (port: backend: ''
              ${config.services.tailscale.package}/bin/tailscale serve --bg --https=${port} ${backend} --yes
            '') cfg.serve)}
          '';
        };
      };

      preservation.preserveAt."/persistent".directories = lib.mkIf (config.preservation.enable or false) [
        {
          directory = "/var/lib/tailscale";
          user = "root";
          group = "root";
          mode = "0755";
        }
      ];
    };
  };
}