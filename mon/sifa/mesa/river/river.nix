{ self, inputs, ... }:
let
  harita = {
    rill = "misuRill";
    canoe = "misuCanoe";
  };
  faleRiver = pkgs: janelaPkt: awto:
  inputs.wrapper-modules.lib.wrapPackage [
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
        constructFiles.river-init = {
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
        env.XDG_CONFIG_HOME = "${placeholder "out"}/config";
      };
    })
    {
      inherit pkgs awto;
      janela = janelaPkt;
    }
  ];
in
{
  flake.nixosModules.sifa.mesa.river =
  { config, pkgs, lib, ... }:
  let
    opsyon = config.drevosim.mesa.river;
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
      services.displayManager.sessionPackages = [
        (
          faleRiver pkgs
          self.packages.${pkgs.stdenv.hostPlatform.system}.${harita.${opsyon.janela}} [ ]
        )
      ];
    };
  };

  perSystem =
  { pkgs, self', lib, ... }:
  lib.mkIf pkgs.stdenv.hostPlatform.isLinux
  {
    packages.misuRiver = faleRiver pkgs self'.packages.misuRill [ ];
  };
}
