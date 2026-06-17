{ self, inputs, ... }:
let
  lib = inputs.nixpkgs.lib;
  yongu = import "${self}/yongu/monlari.nix" { inherit lib; };
in
{
  flake.nixosConfigurations.portaible = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      inputs.nix-maid.nixosModules.default
      inputs.agenix.nixosModules.default
      self.nixosModules.basi
      ({ ... }:
      {
        imports =
          yongu.monlari (self.nixosModules.sifa or {}) ++
          yongu.monlari (self.nixosModules.portaible or {});

        drevosim = {
          mesa.river = {
            enable = true;
            janela = "canoe";
          };
          kuflu.ly.enable = true;
        };
      })
    ];
  };
}
