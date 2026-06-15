{ self, inputs, ... }:
{
  flake.nixosConfigurations.portaible = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      inputs.nix-maid.nixosModules.default
      inputs.agenix.nixosModules.default
      self.nixosModules.portaibleEstrutur
      self.nixosModules.portaibleOgarli
      ({ ... }:
      {

      })
    ];
  };
}
