{ ... }:
{
  flake.nixosModules.basi =
  { lib, ... }:
  {
    options.drevosim.users = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            default = name;
            description = "Git user name for this account. Defaults to the username.";
          };
          email = lib.mkOption {
            type = lib.types.str;
            default = "${name}@email.com";
            description = "Git email for this account. Defaults to <username>@email.com.";
          };
        };
      }));
      description = "Users managed by Drevosim nix-maid, mapped to their metadata.";
    };

    options.drevosim.session.autostart = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Shell commands to run in graphical sessions before the window manager/compositor starts";
    };

    config = {
      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];

      nixpkgs.config.allowUnfree = true;

      nix.gc.automatic = true;
      nix.gc.options = "--delete-older-than 7d";
      nix.settings.auto-optimise-store = true;
    };
  };
}
