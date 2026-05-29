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
        #xwayland-satellite.path = lib.getExe pkgs.xwayland-satellite;
        # TODO: Enable switching between keyboard layouts (e.g. US International and Brazilian ABNT2) on the go
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
