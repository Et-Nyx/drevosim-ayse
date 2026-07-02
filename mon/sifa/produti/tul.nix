{ ... }:
{
  flake.nixosModules.sifa.produti.tul =
  { pkgs, ... }:
  {
    environment.systemPackages = with pkgs; [
      git
      neovim
    ];
  };
}
