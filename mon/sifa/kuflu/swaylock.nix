{ inputs, ... }:
let
  parseSwaylock = import ./../../../yongu/parseSwaylock.nix { lib = inputs.nixpkgs.lib; };
  defaultSettings = parseSwaylock.parseSwaylock { file = ./faylu/swaylock.conf; };

  mkMisuSwaylock = pkgs: settings: inputs.wrapper-modules.wrappers.swaylock.wrap {
    inherit pkgs settings;
  };
in
{
  flake.nixosModules.sifa.kuflu.swaylock =
  { config, lib, pkgs, ... }:
  let
    cfg = config.drevosim.kuflu.swaylock;
  in
  {
    options.drevosim.kuflu.swaylock = {
      enable = lib.mkEnableOption "swaylock screen locker";
      settings = lib.mkOption {
        type = lib.types.attrsOf (lib.types.oneOf [
          lib.types.bool
          lib.types.int
          lib.types.float
          lib.types.str
        ]);
        default = defaultSettings;
        description = "Settings for swaylock config file";
      };
    };

    config = lib.mkIf cfg.enable {
      # Swaylock needs a PAM service to authenticate the unlocking password.
      security.pam.services.swaylock = {};

      environment.systemPackages = [ (mkMisuSwaylock pkgs cfg.settings) ];
    };
  };

  perSystem =
  { pkgs, lib, ... }:
  lib.mkIf pkgs.stdenv.hostPlatform.isLinux
  {
    packages.misuSwaylock = mkMisuSwaylock pkgs defaultSettings;
  };
}
