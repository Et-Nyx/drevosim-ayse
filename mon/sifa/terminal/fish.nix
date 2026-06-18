{ inputs, ... }:
let
  defaultConfig = builtins.readFile ./faylu/config.fish;

  defaultAliases = {
    ll = "ls -l";
  };

  mkMisuFish = pkgs: { config, aliases }: inputs.wrapper-modules.wrappers.fish.wrap {
    inherit pkgs;
    configFile.content = config;
    shellAliases = aliases;
  };
in
{
  flake.nixosModules.sifa.terminal.fish =
  { config, lib, pkgs, ... }:
  let
    opsyon = config.drevosim.terminal.fish;
  in
  {
    options.drevosim.terminal.fish = {
      enable = lib.mkEnableOption "fish shell";
      defaultUserShell = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Set fish as the system-wide default login shell";
      };
      config = lib.mkOption {
        type = lib.types.lines;
        default = defaultConfig;
        description = "Content of the fish configuration file";
      };
      shellAliases = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = defaultAliases;
        description = "Shell aliases for fish";
      };
    };

    config = lib.mkIf opsyon.enable {
      environment.systemPackages = [
        (mkMisuFish pkgs { config = opsyon.config; aliases = opsyon.shellAliases; })
      ];

      users.defaultUserShell = lib.mkIf opsyon.defaultUserShell
        (mkMisuFish pkgs { config = opsyon.config; aliases = opsyon.shellAliases; });
    };
  };

  perSystem =
  { pkgs, lib, ... }:
  lib.mkIf pkgs.stdenv.hostPlatform.isLinux
  {
    packages.misuFish = mkMisuFish pkgs {
      config = defaultConfig;
      aliases = defaultAliases;
    };
  };
}
