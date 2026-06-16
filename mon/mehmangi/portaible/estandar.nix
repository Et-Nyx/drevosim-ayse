{ self, inputs, ... }:
{
  flake.nixosConfigurations.portaible = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.river

      inputs.nix-maid.nixosModules.default
      inputs.agenix.nixosModules.default
      self.nixosModules.portaibleEstrutur
      self.nixosModules.portaibleOgarli
      self.nixosModules.monEstandar
      ({ ... }:
      {

      })
    ];
  };
}
