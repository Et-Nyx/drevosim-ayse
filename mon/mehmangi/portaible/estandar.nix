{ self, inputs, ... }:
{
  flake.nixosConfigurations.portaible = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      inputs.nix-maid.nixosModules.default
      inputs.agenix.nixosModules.default
      self.nixosModules.portaibleEstrutur
      self.nixosModules.portaibleOgarli
      
      # The dynamic module that bundles all A La Carte modules!
      self.nixosModules.monEstandar

      # Toggles for features bundled cleanly in a single, recursively nested attribute set!
      ({ ... }: {
        taluji.sifa = {
          programa = {
            alo.enable = true;
            git.enable = true;
          };
          kuflu = {
            ly.enable = true;
          };
          mesa = {
            kexru = {
              river = {
                enable = true;
                layoutManager = "kwm";
              };
            };
            noctalia-shell = {
              niri.enable = true;
              noctalia.enable = true;
            };
          };
          terminal = {
            foot.enable = true;
            fish.enable = true;
          };
          browsetul = {
            librewolf.enable = true;
          };
          yongu = {
            fuzzel.enable = true;
          };
          produti = {
            neovim.enable = true;
            zed.enable = true;
            basa.enable = true;
          };
          servi = {
            kanshi.enable = true;
            bluetooth.enable = true;
            tlp.enable = true;
          };
          medya = {
            brightnessctl.enable = true;
            pamixer.enable = true;
            pipewire.enable = true;
            wob.enable = true;
          };
        };
      })
    ];
  };
}
