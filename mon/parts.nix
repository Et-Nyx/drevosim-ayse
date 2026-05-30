{ self, inputs, ... }:
{
  config = {
    systems = [
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-linux"
      "aarch64-darwin"
    ];

    flake.nixosModules.monEstandar = { lib, ... }: {
      imports = let
        # Checks if a module name is strictly lowercase (indicating it is a sifa feature module)
        isFeatureModule = name: name == inputs.nixpkgs.lib.toLower name;

        featureModuleNames = builtins.filter isFeatureModule (builtins.attrNames self.nixosModules);
      in
        builtins.map (name: self.nixosModules.${name}) featureModuleNames;

      options.taluji.userName = lib.mkOption {
        type = lib.types.str;
        default = "eter";
        description = "Primary user name used by feature modules for per-user (nix-maid) configuration.";
      };
    };
  };
}
