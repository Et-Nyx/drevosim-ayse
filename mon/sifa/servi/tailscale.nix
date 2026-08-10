{ ... }:
{
  flake.nixosModules.sifa.servi.tailscale =
  { config, lib, ... }:
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
    };

    config = lib.mkIf cfg.enable {
      services.tailscale = {
        enable = true;
        openFirewall = true;
        authKeyFile = cfg.authKeyFile;
      };

      # Web services reachable ONLY over the tailnet; MagicDNS gives them
      # http://ayse.<tailnet>.ts.net:<port> URLs from the phone.
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = cfg.ports;

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