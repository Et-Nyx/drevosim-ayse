{ self, inputs, ... }:
{
  flake.nixosModules.river =
    { pkgs, lib, config, ... }:
    let
      cfg = config.taluji.sifa.mesa.kexru.river;
    in
    {
      options.taluji.sifa.mesa.kexru.river = {
        enable = lib.mkEnableOption "River wayland compositor session";
        layoutManager = lib.mkOption {
          type = lib.types.enum [ "kwm" "none" ];
          default = "kwm";
          description = "The window/layout manager to pair with River.";
        };
      };
      config = lib.mkIf cfg.enable {
        taluji.sifa.mesa.kexru.kwm.enable = lib.mkDefault (cfg.layoutManager == "kwm");
        environment.systemPackages = [ pkgs.river ];

        # When kwm is the layout manager it both registers the river-kwm session and
        # sets RIVER_WM. For "none", register a plain river session and point RIVER_WM
        # at rivertile so the init script still has a layout generator to exec.
        services.displayManager.sessionPackages =
          lib.optionals (cfg.layoutManager == "none") [ pkgs.river ];
        environment.sessionVariables = lib.optionalAttrs (cfg.layoutManager == "none") {
          RIVER_WM = "${pkgs.river}/bin/rivertile";
        };

        users.users.${config.taluji.userName}.maid = {
          file.xdg_config."river/init" = {
            text = /* bash */ ''
              dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
              systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
              systemctl --user start graphical-session.target
              kanshi &
              exec ''${RIVER_WM:-${pkgs.river}/bin/rivertile}
            '';
            executable = true;
          };
        };
      };
    };
}
