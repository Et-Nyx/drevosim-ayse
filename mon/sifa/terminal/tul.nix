{ ... }:
{
  flake.nixosModules.sifa.terminal.tul =
  { pkgs, ... }:
  {
    environment.systemPackages = with pkgs; [
      # Generic CLI tools (non-specific to other categories).
    ];
  };
}
