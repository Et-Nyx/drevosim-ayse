{ ... }:
{
  flake.nixosModules.sifa.terminal.tul =
  { pkgs, ... }:
  {
    environment.systemPackages = with pkgs; [
      tree
      fastfetch
    ];
  };
}
