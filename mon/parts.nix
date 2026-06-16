{ ... }:
{
  config = {
    systems = [
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-linux"
      "aarch64-darwin"
    ];

    flake.nixosModules.basi =
    { lib, ... }:
    {
      options.drevosim.userName = lib.mkOption {
        type = lib.types.str;
        default = "eter";
        description = "The username to use for the Drevosim nix-maid";
      };
    };
  };
}
