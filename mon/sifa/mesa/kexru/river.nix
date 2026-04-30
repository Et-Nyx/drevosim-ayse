{ self, inputs, ... }:
{
  flake.nixosModules.river =
  { pkgs, lib, ... }:
  {
    imports = [
      self.nixosModules.kwm
    ];
    environment.systemPackages = [ pkgs.river ];
    users.users.eter.maid = {
      file.xdg_config."river/init" = {
        text = /* sh */ ''
          #!/bin/sh
	  dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
          systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
          systemctl --user start graphical-session.target
	  kanshi &
	  exec $RIVER_WM
        '';
        executable = true;
      };
    };
  };
}
