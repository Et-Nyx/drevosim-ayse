{ inputs, ... }:
let
  defaultConfig = builtins.readFile ./faylu/config.nu;

  mkMisuNushell = pkgs: config:
  let
    wrapped = inputs.wrapper-modules.wrappers.nushell.wrap {
      inherit pkgs;
      "config.nu".content = config;
    };
  in
  pkgs.runCommand "misuNushell"
  {
    nativeBuildInputs = [ pkgs.makeWrapper ];
    passthru.shellPath = "${wrapped.passthru.shellPath}";
  }
  ''
    mkdir -p $out/bin
    makeWrapper ${wrapped}/bin/nu $out/bin/nu \
      --run 'export XDG_CONFIG_HOME="''${XDG_CONFIG_HOME:-$HOME/.config}"' \
      --run 'mkdir -p "$XDG_CONFIG_HOME/nushell"'
  '';
in
{
  flake.nixosModules.sifa.terminal.nushell =
  { config, lib, pkgs, ... }:
  let
    cfg = config.drevosim.terminal.nushell;
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

    config = lib.mkIf cfg.enable {
      environment.systemPackages = [ (mkMisuNushell pkgs cfg.config) ];

      users.defaultUserShell = lib.mkIf cfg.defaultUserShell
        (mkMisuNushell pkgs cfg.config);
    };
  };

  perSystem =
  { pkgs, lib, ... }:
  lib.mkIf pkgs.stdenv.hostPlatform.isLinux
  {
    packages.misuNushell = mkMisuNushell pkgs defaultConfig;
  };
}
