{ ... }:
{
  flake.nixosModules.sifa.servi.adguard =
  { config, lib, pkgs, ... }:
  let
    cfg = config.drevosim.servi.adguard;
  in
  {
    options.drevosim.servi.adguard = {
      enable = lib.mkEnableOption "AdGuard Home DNS-level adblocker for the tailnet";

      tailscaleIp = lib.mkOption {
        type = lib.types.str;
        default = "100.75.243.95";
        description = ''
          Tailscale IPv4 of this node. The DNS listener binds here (plus
          localhost) and the tailnet's global nameserver must point here.
          If the node's Tailscale IP ever changes, update this AND the
          nameserver entry in the Tailscale admin console.
        '';
      };

      webPort = lib.mkOption {
        type = lib.types.port;
        default = 3000;
        description = "Local port of the AdGuard Home dashboard, exposed via Tailscale Serve.";
      };

      upstreams = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "https://dns.cloudflare.com/dns-query"
          "https://dns.google/dns-query"
        ];
        description = ''
          Upstream resolvers, queried in parallel (all_servers). DoH keeps
          upstream queries encrypted. These MUST NOT point at
          100.100.100.100 (the Tailscale stub) or a resolver loop forms.
        '';
      };

      bootstrapDns = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "1.1.1.1" "8.8.8.8" "9.9.9.9" ];
        description = "Plain DNS used only to resolve the DoH upstream hostnames.";
      };
    };

    config = lib.mkIf cfg.enable {
      services.adguardhome = {
        enable = true;
        # Dashboard binds loopback only; Tailscale Serve terminates HTTPS on
        # the tailnet and proxies here. Firewall never opens this port.
        host = "127.0.0.1";
        port = cfg.webPort;

        # Bootstrap settings. With mutableSettings (default true) the Nix
        # values are merged into /var/lib/AdGuardHome/AdGuardHome.yaml on
        # start; edits made in the dashboard persist across rebuilds.
        settings = {
          dns = {
            # Deliberately NOT 0.0.0.0: tailscaled already binds
            # 100.100.100.100:53 (MagicDNS stub) and would collide.
            bind_hosts = [ "127.0.0.1" cfg.tailscaleIp ];
            port = 53;
            protection_enabled = true;
            filtering_enabled = true;
            all_servers = true;
            upstream_dns = cfg.upstreams;
            bootstrap_dns = cfg.bootstrapDns;
          };
          filters = [
            {
              enabled = true;
              url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
              name = "AdGuard DNS filter";
              id = 1;
            }
            {
              enabled = true;
              url = "https://small.oisd.nl/dnsmasq";
              name = "OISD Small";
              id = 2;
            }
          ];
        };
      };

      # Binding cfg.tailscaleIp requires the tailscale0 address to exist, so
      # order after tailscaled; Restart=always (from the upstream module)
      # covers any remaining race.
      systemd.services.adguardhome.after = [ "tailscaled.service" ];

      # DNS for tailnet clients (direct, not via Serve).
      networking.firewall.interfaces.tailscale0 = {
        allowedTCPPorts = [ 53 ];
        allowedUDPPorts = [ 53 ];
      };

      # Dashboard over the tailnet: https://ayse.<tailnet>.ts.net:<webPort>.
      # ports (listOf) and serve (attrsOf) MERGE with values from other
      # modules, so nothing is clobbered.
      drevosim.servi.tailscale.ports = [ cfg.webPort ];
      drevosim.servi.tailscale.serve."${toString cfg.webPort}" =
        "127.0.0.1:${toString cfg.webPort}";
    };
  };
}
