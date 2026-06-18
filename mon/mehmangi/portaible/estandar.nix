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
          kuflu = {
            ly = {
              enable = true;
              settings = {
                bigclock = "en";
              };
            };
            swaylock.enable = true;
          };
          mesa.river = {
            enable = true;
            janela = "canoe";
          };
          terminal = {
            foot.enable = true;
            fish = {
              enable = true;
              defaultUserShell = true;
            };
            nushell = {
              enable = true;
              defaultUserShell = false;
            };
          };
          programa = {
            fuzzel.enable = true;
          };
        };
      })
    ];
  };
}
