{ ... }:
{
  flake.nixosModules.sifa.produti.tul =
  { pkgs, ... }:
  {
    environment.systemPackages = with pkgs; [
      neovim
      zed-editor
    ];
  };
}
