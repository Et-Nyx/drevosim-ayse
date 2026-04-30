{ self, inputs, ... }:
{
  flake.nixosModules.neovim =
  { pkgs, ... }:
  let
    misuNeovim = self.packages.${pkgs.stdenv.hostPlatform.system}.misuNeovim;
  in
  {
    programs.neovim = {
      enable = true;
      package = misuNeovim;
    };
  };

  perSystem =
    { pkgs, lib, ... }:
    {
        packages.misuNeovim = inputs.wrapper-modules.wrappers.neovim.wrap {
            inherit pkgs;
        };
    };
}
