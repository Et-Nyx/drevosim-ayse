{ inputs, ... }:
let
  defaultSettings = builtins.readFile ./faylu/settings.json;

  mkMisuGrayjay = pkgs: settings:
  let
    wrapper = pkgs.writeShellScriptBin "Grayjay" ''
      set -e

      if [ -n "$XDG_DATA_HOME" ] && [ -d "$XDG_DATA_HOME" ]; then
        data_dir="$XDG_DATA_HOME/Grayjay"
      else
        data_dir="$HOME/.local/share/Grayjay"
      fi

      ${pkgs.coreutils}/bin/mkdir -p "$data_dir"
      ${pkgs.coreutils}/bin/cp -f ${pkgs.writeText "settings.json" settings} "$data_dir/settings.json"

      exec ${pkgs.grayjay}/bin/Grayjay "$@"
    '';
  in
  pkgs.symlinkJoin {
    name = "Grayjay";
    paths = [ wrapper pkgs.grayjay ];
  };
in
{
  flake.nixosModules.sifa.medya.grayjay =
  { config, lib, pkgs, ... }:
  let
    cfg = config.drevosim.medya.grayjay;
  in
  {
    options.drevosim.medya.grayjay = {
      enable = lib.mkEnableOption "Grayjay desktop media app" // {
        default = true;
      };
      openFirewall = lib.mkEnableOption "open firewall for Grayjay LAN sync" // {
        default = true;
      };
      settings = lib.mkOption {
        type = lib.types.lines;
        default = defaultSettings;
        description = ''
          Grayjay settings.json content. Re-applied on every launch (cp -f),
          so any changes you make in the Grayjay UI will be reverted on
          next rebuild + restart. Override this option to change defaults.
        '';
      };
    };

    config = lib.mkIf cfg.enable {
      nixpkgs.config.allowUnfreePackages = [ "grayjay" ];

      environment.systemPackages = [ (mkMisuGrayjay pkgs cfg.settings) ];

      systemd.tmpfiles.rules = [
        "d /home/eter/.local/share 0755 eter users - -"
        "d /persistent/share/Grayjay 0755 eter users - -"
        "L+ /home/eter/.local/share/Grayjay - - - - /persistent/share/Grayjay"
      ];

      preservation.preserveAt."/persistent".directories = lib.mkIf (config.preservation.enable or false) [
        {
          directory = "/persistent/share/Grayjay";
          user = "eter";
          group = "users";
          mode = "0755";
        }
      ];

      networking.firewall = lib.mkIf cfg.openFirewall {
        allowedTCPPorts = [ 11338 ];
        allowedUDPPorts = [ 5353 ];
      };
    };
  };

  perSystem =
  { system, lib, ... }:
  lib.mkIf (system == "x86_64-linux" || system == "aarch64-linux") (let
    # pkgs.grayjay is SFL-licensed. The flake-level nixpkgs doesn't carry
    # `allowUnfree = true`, so re-import with a targeted allowlist to expose
    # `misuGrayjay` for `nix run`.
    pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfreePackages = [ "grayjay" ];
    };
  in {
    packages.misuGrayjay = mkMisuGrayjay pkgs defaultSettings;
  });
}