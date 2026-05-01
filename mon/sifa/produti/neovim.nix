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
            specs.basic = {
              config = /* lua */ ''
                vim.opt.tabstop = 2
                vim.opt.shiftwidth = 2
                vim.opt.expandtab = true
                vim.opt.number = true
                vim.opt.relativenumber = true
                vim.opt.splitbelow = true
                vim.opt.splitright = true
                vim.opt.clipboard = "unnamedplus"
              '';
            };
        };
    };
}
