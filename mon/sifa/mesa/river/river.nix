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
          exec $RIVER_WM
        '';
        executable = true;
      };
    };
  };
}
