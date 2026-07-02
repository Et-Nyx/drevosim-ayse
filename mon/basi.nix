{ ... }:
{
  flake.nixosModules.basi =
  { lib, ... }:
  {
    options.drevosim.userName = lib.mkOption {
      type = lib.types.str;
      default = "eter";
      description = "The username to use for the Drevosim nix-maid";
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
