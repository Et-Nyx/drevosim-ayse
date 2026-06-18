{ ... }:
let
  mkMisuWaylock = pkgs:
    pkgs.writeShellScriptBin "waylock" ''
      exec ${pkgs.waylock}/bin/waylock -init-color 1e1e1e -input-color ffd000 "$@"
    '';
in
{
  flake.nixosModules.sifa.kuflu.waylock =
  { config, lib, pkgs, ... }:
  let
    cfg = config.drevosim.kuflu.waylock;
  in
  {
    options.drevosim.kuflu.waylock = {
      enable = lib.mkEnableOption "waylock screen locker";
    };

    config = lib.mkIf cfg.enable {
      # waylock needs a PAM service to authenticate the unlocking password.
      security.pam.services.waylock = {};

      environment.systemPackages = [ (mkMisuWaylock pkgs) ];
    };
  };

  perSystem =
  { pkgs, lib, ... }:
  lib.mkIf pkgs.stdenv.hostPlatform.isLinux
  {
    packages.misuWaylock = mkMisuWaylock pkgs;
  };
}
