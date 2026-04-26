{ self, inputs, ... }:
{
  flake.nixosModules.niri =
  { pkgs, lib, ... }:
  let
    misuNiri = self.packages.${pkgs.stdenv.hostPlatform.system}.misuNiri;
  in
  {
    programs.niri = {
      enable = true;
      package = misuNiri;
    };
  };
  perSystem =
  { pkgs, lib, self', ... }:
  let
    misuFoot = lib.getExe self'.packages.misuFoot;
    misuNoctalia = lib.getExe self'.packages.misuNoctalia;
  in
  {
    packages.misuNiri = inputs.wrapper-modules.wrappers.niri.wrap {
      inherit pkgs;
      settings = {
        spawn-at-startup = [
          { command = [ misuNoctalia ]; }
        ];
        xwayland-satellite.path = lib.getExe pkgs.xwayland-satellite;
        input.keyboard = {
          xkb.layout = "us";
          xkb.variant = "intl";
        };
        layout.gaps = 5;
        binds = {
          "Mod+Return".spawn-sh = misuFoot;
          "Mod+Q".close-window = null;
          "Mod+S".spawn-sh = "${misuNoctalia} ipc call launcher toggle";
        };
      };
    };
  };
}
