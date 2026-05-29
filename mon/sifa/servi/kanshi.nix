{ self, inputs, ... }:
{
  flake.nixosModules.kanshi =
    { pkgs, lib, config, ... }:
    let
      cfg = config.taluji.sifa.servi.kanshi;
    in
    {
      options.taluji.sifa.servi.kanshi = {
        enable = lib.mkEnableOption "Kanshi display daemon and service";
      };
      config = lib.mkIf cfg.enable {
        environment.systemPackages = with pkgs; [
          kanshi
          wlr-randr
        ];
        users.users.eter.maid = {
          file.xdg_config."kanshi/config" = {
            text = ''
              profile undocked {
                output eDP-1 enable
              }
              profile docked {
                output eDP-1 disable
                output DP-1 enable position 0,0
              }
            '';
          };
          systemd.services.kanshi = {
            description = "Kanshi servi";
            partOf = [ "graphical-session.target" ];
            after = [ "graphical-session.target" ];
            serviceConfig = {
              ExecStart = "${pkgs.kanshi}/bin/kanshi";
              Restart = "always";
            };
            wantedBy = [ "graphical-session.target" ];
          };
        };
      };
    };
}
