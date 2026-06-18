{ ... }:
let
  defaultConfig = builtins.readFile ./faylu/config.nu;

  mkMisuNushell = pkgs: config:
  let
    configNu = pkgs.writeTextFile {
      name = "nushell-config.nu";
      text = config;
    };
    envNu = pkgs.writeTextFile {
      name = "nushell-env.nu";
      text = "";
    };
  in
  (pkgs.writeShellScriptBin "nu" ''
    if [ -n "$HOME" ]; then
      export XDG_CONFIG_HOME="$HOME/.config"
    else
      export XDG_CONFIG_HOME="/run/user/$(${pkgs.coreutils}/bin/id -u)"
      if [ ! -d "$XDG_CONFIG_HOME" ]; then
        export XDG_CONFIG_HOME="/tmp/nushell-$(${pkgs.coreutils}/bin/id -u)"
      fi
    fi

    ${pkgs.coreutils}/bin/mkdir -p "$XDG_CONFIG_HOME/nushell"
    ${pkgs.coreutils}/bin/cp -f ${configNu} "$XDG_CONFIG_HOME/nushell/config.nu"
    ${pkgs.coreutils}/bin/cp -f ${envNu} "$XDG_CONFIG_HOME/nushell/env.nu"

    exec ${pkgs.nushell}/bin/nu "$@"
  '').overrideAttrs (old: {
    passthru = (old.passthru or {}) // { shellPath = "/bin/nu"; };
  });
in
{
  flake.nixosModules.sifa.terminal.nushell =
  { config, lib, pkgs, ... }:
  let
    opsyon = config.drevosim.terminal.nushell;
  in
  {
    options.drevosim.terminal.nushell = {
      enable = lib.mkEnableOption "nushell";
      defaultUserShell = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Set nushell as the system-wide default login shell";
      };
      config = lib.mkOption {
        type = lib.types.lines;
        default = defaultConfig;
        description = "Content of config.nu";
      };
    };

    config = lib.mkIf opsyon.enable {
      environment.systemPackages = [ (mkMisuNushell pkgs opsyon.config) ];

      users.defaultUserShell = lib.mkIf opsyon.defaultUserShell
        (mkMisuNushell pkgs opsyon.config);
    };
  };

  perSystem =
  { pkgs, lib, ... }:
  lib.mkIf pkgs.stdenv.hostPlatform.isLinux
  {
    packages.misuNushell = mkMisuNushell pkgs defaultConfig;
  };
}
