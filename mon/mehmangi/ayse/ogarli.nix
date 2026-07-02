{ ... }:
{
  flake.nixosModules.ayse.ogarli =
  { pkgs, ... }:
  {
    users.users.eter = {
      isNormalUser = true;
      initialPassword = "1234";
      extraGroups = [
        "wheel"
        "networkmanager"
      ];
      packages = with pkgs; [
        tree
      ];
    };
  };
}
