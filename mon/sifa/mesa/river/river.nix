{ self, inputs, ... }:
{
  flake.nixosModules.river =
  { pkgs, ... }:
  {
    services.displayManager.sessionPackages = [
      self.packages.${pkgs.stdenv.hostPlatform.system}.river
    ];
  };

  perSystem =
  { pkgs, self', lib, ... }:
  lib.mkIf pkgs.stdenv.hostPlatform.isLinux
  {
    packages.misuRiver = inputs.wrapper-modules.lib.wrapPackage [
      ({ config, lib, wlib, ... }:
      {
        imports = [ wlib.modules.default ];
        options = {
          janela = lib.mkOption {
            type = lib.types.package;
            description = "Window manager to exec inside river";
          };
          autostart = lib.mkOption {
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
              ${lib.concatStringsSep "\n" config.autostart}
              exec ${lib.getExe config.windowManager}
            '';
          };
          env.XDG_CURRENT_DESKTOP = "${placeholder "out"}/config";
        };
      })
      {
        inherit pkgs;
        windowManager = self'.packages.misuRill;
        autostart = [ ];
      }
    ];
  };
}
