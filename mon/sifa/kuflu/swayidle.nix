{ ... }:
{
  flake.nixosModules.sifa.kuflu.swayidle =
  { config, lib, pkgs, ... }:
  let
    cfg = config.drevosim.kuflu.swayidle;
  in
  {
    options.drevosim.kuflu.swayidle = {
      enable = lib.mkEnableOption "swayidle auto-lock";
      lockCmd = lib.mkOption {
        type = lib.types.str;
        default = "swaylock -f";
        description = "Command to run when the idle timeout is reached.";
      };
      timeoutSeconds = lib.mkOption {
        type = lib.types.ints.positive;
        default = 300;
        description = "Idle time in seconds before locking the session.";
      };
    };

    config = lib.mkIf cfg.enable {
      environment.systemPackages = [ pkgs.swayidle ];
      drevosim.mesa.river.awto = lib.mkIf config.drevosim.mesa.river.enable [
        "${lib.getExe pkgs.swayidle} -w timeout ${toString cfg.timeoutSeconds} '${cfg.lockCmd}'"
      ];
    };
  };
}
