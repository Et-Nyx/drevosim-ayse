{ self, inputs, ... }:
let
  lib = inputs.nixpkgs.lib;
  yongu = import "${self}/yongu/monlari.nix" { inherit lib; };
in
{
  flake.nixosConfigurations.ayse = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      inputs.disko.nixosModules.disko
      inputs.preservation.nixosModules.default
      inputs.agenix.nixosModules.default
      inputs.nix-maid.nixosModules.default
      self.nixosModules.basi
      ({ ... }: {
        imports =
          yongu.monlari (self.nixosModules.sifa or {}) ++
          yongu.monlari (self.nixosModules.ayse or {});

        drevosim.servi.sillytavern.enable = true;
        drevosim.servi.kokoro.enable = true;
        drevosim.servi.ftp.enable = true;
      })
    ];
  };
}
