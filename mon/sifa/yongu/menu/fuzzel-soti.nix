{ self, ... }:
{
  flake.nixosModules.fuzzel-soti =
    { pkgs, lib, config, ... }:
    let
      parent = config.taluji.sifa.yongu.fuzzel;
      cfg = parent.soti;
      misuFuzzel = self.packages.${pkgs.stdenv.hostPlatform.system}.misuFuzzel;
    in
    {
      options.taluji.sifa.yongu.fuzzel.soti.enable =
        lib.mkEnableOption "Fuzzel audio menu (output picker + volume)";
      config = lib.mkIf (parent.enable && cfg.enable) {
        environment.systemPackages = [
          (pkgs.writeShellApplication {
            name = "fuzzel-soti";
            runtimeInputs = with pkgs; [
              misuFuzzel
              wireplumber
              pamixer
              libnotify
              gawk
              coreutils
            ];
            text = /* bash */ ''
              push_wob() {
                if [ -p "$XDG_RUNTIME_DIR/wob.fifo" ]; then
                  pamixer --get-volume > "$XDG_RUNTIME_DIR/wob.fifo"
                fi
              }

              # Pull WirePlumber playback sinks. Field 1 of each sink line is the
              # object ID — what `wpctl set-default` expects (not pamixer's index).
              SINKS=$(wpctl status | gawk '
                /Sinks:/ { in_section = 1; next }
                /Sources:|Filters:|Streams:/ { in_section = 0 }
                in_section && match($0, /([0-9]+)\.[[:space:]]+(.+)[[:space:]]+\[vol:/, m) {
                  printf "%s: %s\n", m[1], m[2]
                }
              ')

              MENU=$({
                printf '%s\n' "Vol +5%" "Vol -5%" "Mute toggle" "---"
                printf '%s' "$SINKS"
              } | fuzzel --dmenu -p "Audio: " || true)
              [ -n "$MENU" ] || exit 0

              case "$MENU" in
                "Vol +5%")     pamixer -i 5; push_wob ;;
                "Vol -5%")     pamixer -d 5; push_wob ;;
                "Mute toggle") pamixer -t;   push_wob ;;
                ---) ;;
                *)
                  ID=$(printf '%s' "$MENU" | cut -d: -f1)
                  NAME=$(printf '%s' "$MENU" | cut -d: -f2-)
                  NAME=''${NAME# }
                  wpctl set-default "$ID"
                  notify-send "Audio Output" "Active device: $NAME"
                  ;;
              esac
            '';
          })
        ];
      };
    };
}
