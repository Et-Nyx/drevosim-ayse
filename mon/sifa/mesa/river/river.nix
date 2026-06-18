{ self, inputs, ... }:
let
  lib = inputs.nixpkgs.lib;
  harita = {
    rill = "misuRill";
    canoe = "misuCanoe";
  };
  mkMisuRiver = pkgs: janelaPkt: awto:
  let
    lifafa = inputs.wrapper-modules.lib.wrapPackage [
      ({ config, lib, wlib, ... }:
      {
        imports = [ wlib.modules.default ];
        options = {
          janela = lib.mkOption {
            type = lib.types.package;
            description = "Window manager to exec inside river";
          };
          awto = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Shell commands to run in river/init before the WM";
          };
        };
        config = {
          package = pkgs.river;
          constructFiles = {
            river-init = {
              relPath = "config/river/init";
              content = ''
                #!${lib.getExe pkgs.bash}
                ${lib.concatStringsSep "\n" config.awto}
                exec ${lib.getExe config.janela}
              '';
              builder = ''
                cp "$1" "$2"
                chmod +x "$2"
              '';
            };
            river-desktop = {
              relPath = "share/wayland-sessions/river.desktop";
              content = builtins.readFile "${pkgs.river}/share/wayland-sessions/river.desktop";
            };
          };
          env.XDG_CONFIG_HOME = "${placeholder "out"}/config";
        };
      })
      {
        inherit pkgs awto;
        janela = janelaPkt;
      }
    ];
  in
  lib.extendDerivation true {
    providedSessions = [ "river" ];
  } lifafa;
in
{
  flake.nixosModules.sifa.mesa.river =
  { config, pkgs, lib, ... }:
  let
    opsyon = config.drevosim.mesa.river;
    misuRiver = mkMisuRiver pkgs self.packages.${pkgs.stdenv.hostPlatform.system}.${harita.${opsyon.janela}} [ ];
  in
  {
    options.drevosim.mesa.river = {
      enable = lib.mkEnableOption "river wayland compositor";
      janela = lib.mkOption {
        type = lib.types.enum [ "rill" "canoe" ];
        default = "rill";
        description = "Window manager to exec inside river";
      };
    };
    config = lib.mkIf opsyon.enable {
      services.displayManager.sessionPackages = [ misuRiver ];
      environment.systemPackages = [ misuRiver ];
    };
  };

  perSystem =
  { pkgs, self', lib, ... }:
  lib.mkIf pkgs.stdenv.hostPlatform.isLinux
  {
    packages.misuRiver = mkMisuRiver pkgs self'.packages.misuRill [ ];
  };
}
