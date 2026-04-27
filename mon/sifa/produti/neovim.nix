{ self, inputs, ... }:
{
  flake.nixosModules.neovim = 
  { pkgs, ... }:
  {
    programs.neovim = {
      enable = true;
      package = self.packages.${pkgs.stdenv.hostPlatform.system}.misuNeovim;
    };
  };
  perSystem = 
  { pkgs, ... }:
  {
    packages.misuNeovim = inputs.wrapper-modules.wrappers.neovim.wrap {
      inherit pkgs;
    };
  };
}
