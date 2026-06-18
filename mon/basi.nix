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

    config = {
      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];

      nixpkgs.config.allowUnfree = true;
    };
  };
}
