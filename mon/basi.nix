{ ... }:
{
  flake.nixosModules.basi =
  { lib, ... }:
  {
    options.drevosim.autostart = lib.mkOption {
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
