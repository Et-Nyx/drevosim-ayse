{ self, inputs, ... }:
{
  flake.nixosModules.fuzzel =
    { pkgs, lib, config, ... }:
    let
      cfg = config.taluji.sifa.yongu.fuzzel;
      misuFuzzel = self.packages.${pkgs.stdenv.hostPlatform.system}.misuFuzzel;
    in
    {
      options.taluji.sifa.yongu.fuzzel = {
        enable = lib.mkEnableOption "Fuzzel application launcher";
        energi = {
          enable = lib.mkEnableOption "Fuzzel power menu launcher";
        };
        soti = {
          enable = lib.mkEnableOption "Fuzzel audio output selector";
        };
      };
      config = lib.mkIf cfg.enable {
        environment.systemPackages = [ misuFuzzel ]
          ++ lib.optional cfg.energi.enable (pkgs.writeShellApplication {
            name = "fuzzel-energi";
            runtimeInputs = with pkgs; [
              misuFuzzel
              systemd
            ];
            text = /* bash */''
              # Power menu options
              OPTIONS="🔒 Lock\n💤 Suspend\n🔄 Reboot\n🛑 Shutdown\n🚪 Log out"

              # Run fuzzel as a dmenu selector
              CHOICE=$(echo -e "$OPTIONS" | fuzzel --dmenu -p "Power: ")

              case "$CHOICE" in
                "🔒 Lock")
                  loginctl lock-session
                  ;;
                "💤 Suspend")
                  systemctl suspend
                  ;;
                "🔄 Reboot")
                  systemctl reboot
                  ;;
                "🛑 Shutdown")
                  systemctl poweroff
                  ;;
                "🚪 Log out")
                  if command -v riverctl >/dev/null 2>&1; then
                    riverctl exit
                  else
                    loginctl terminate-user "$USER"
                  fi
                  ;;
              esac
            '';
          })
          ++ lib.optional cfg.soti.enable (pkgs.writeShellApplication {
            name = "fuzzel-soti";
            runtimeInputs = with pkgs; [
              misuFuzzel
              wireplumber
              pamixer
              wob
              gnused
              gnugrep
              coreutils
              libnotify
              gawk
            ];
            text = /* bash */''
              # 1. Fetch clean playback sinks list using pamixer (skip the header line)
              SINKS=$(pamixer --list-sinks | tail -n +2)

              if [ -z "$SINKS" ]; then
                notify-send "Audio Error" "No active playback devices found"
                exit 1
              fi

              # 2. Let user select via fuzzel
              CHOICE=$(echo "$SINKS" | fuzzel --dmenu -p "Audio Output: ")

              if [ -n "$CHOICE" ]; then
                # 3. Extract the clean index number (field 2)
                ID=$(echo "$CHOICE" | awk '{print $2}')
                
                # 4. Switch the audio sink
                wpctl set-default "$ID"

                # 5. Extract a clean name for the notification (string inside double quotes)
                NAME=$(echo "$CHOICE" | cut -d'"' -f2)
                notify-send "Audio Output" "Active device: $NAME"

                # 6. Wob Integration: Display the new device's volume instantly!
                RAW_VOL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2}')
                
                # Convert decimal to integer (0-100)
                INT_VOL=$(awk -v v="$RAW_VOL" 'BEGIN {print int(v * 100)}')

                # Send value to wob's named pipe if it exists
                if [ -p "$XDG_RUNTIME_DIR/wob.fifo" ]; then
                  echo "$INT_VOL" > "$XDG_RUNTIME_DIR/wob.fifo"
                fi
              fi
            '';
          });
        environment.sessionVariables.FUZZEL_LAUNCHER = "${misuFuzzel}/bin/fuzzel";
      };
    };
  perSystem = { pkgs, ... }:
  {
    packages.misuFuzzel = inputs.wrapper-modules.wrappers.fuzzel.wrap {
      inherit pkgs;
      settings = {
        main = {
          font = "monospace:size=12";
          dpi-aware = "auto";
          icons-enabled = "yes";
          match-mode = "fzf";
        };
      };
    };
  };
}
