{ self, inputs, ... }:
{
  flake.nixosConfigurations.portaible = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      inputs.nix-maid.nixosModules.default
      self.nixosModules.portaibleEstrutur
      self.nixosModules.portaibleOgarli
      self.nixosModules.alo
      self.nixosModules.ly
      #self.nixosModules.river-classic
      self.nixosModules.river
      self.nixosModules.foot
      self.nixosModules.fish
      self.nixosModules.librewolf
      self.nixosModules.fuzzel
      self.nixosModules.niri
      self.nixosModules.noctalia
      self.nixosModules.neovim
      self.nixosModules.kanshi
      self.nixosModules.git
      self.nixosModules.zed
    ];
  };
}
