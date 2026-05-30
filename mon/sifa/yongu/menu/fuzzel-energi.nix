{ self, ... }:
{
  flake.nixosModules.fuzzel-energi =
    { pkgs, lib, config, ... }:
    let
      parent = config.taluji.sifa.yongu.fuzzel;
      cfg = parent.energi;
      misuFuzzel = self.packages.${pkgs.stdenv.hostPlatform.system}.misuFuzzel;
    in
    {
      options.taluji.sifa.yongu.fuzzel.energi.enable =
        lib.mkEnableOption "Fuzzel power menu";
      config = lib.mkIf (parent.enable && cfg.enable) {
        environment.systemPackages = [
          (pkgs.writeShellApplication {
            name = "fuzzel-energi";
            runtimeInputs = [ misuFuzzel pkgs.systemd ];
            text = /*  */ ''
              CHOICE=$(printf '%s\n' Lock Suspend Reboot Shutdown Logout \
                | fuzzel --dmenu -p "Power: " || true)
              case "$CHOICE" in
                Lock)     loginctl lock-session ;;
                Suspend)  systemctl suspend ;;
                Reboot)   systemctl reboot ;;
                Shutdown) systemctl poweroff ;;
                Logout)   loginctl terminate-user "$USER" ;;
              esac
            '';
          })
        ];
      };
    };
}
