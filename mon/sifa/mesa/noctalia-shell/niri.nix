{ self, inputs, ... }:
{
  flake.nixosModules.niri =
    { pkgs, lib, config, ... }:
    let
      cfg = config.taluji.sifa.mesa.noctalia-shell.niri;
      misuNiri = self.packages.${pkgs.stdenv.hostPlatform.system}.misuNiri;
    in
    {
      options.taluji.sifa.mesa.noctalia-shell.niri = {
        enable = lib.mkEnableOption "Niri window manager configuration";
      };
      config = lib.mkIf cfg.enable {
        programs.niri = {
          enable = true;
          package = misuNiri;
        };
      };
    };
  perSystem =
    { pkgs, lib, self', ... }:
    let
      misuFoot = self'.packages.misuFoot;
      misuNoctalia = self'.packages.misuNoctalia;
    in
    {
      packages.misuNiri = inputs.wrapper-modules.wrappers.niri.wrap {
        inherit pkgs;
        settings = {
          spawn-at-startup = [
            (lib.getExe misuNoctalia)
          ];
          input.keyboard = {
            xkb.layout = "us";
            xkb.variant = "intl";
          };
          layout.gaps = 5;
          binds = {
            "Mod+Return".spawn-sh = lib.getExe misuFoot;
            "Mod+Q".close-window = {};
            "Mod+S".spawn-sh = "${lib.getExe misuNoctalia} ipc call launcher toggle";
          };
        };
      };
    };
}
