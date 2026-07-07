{ ... }:
{
  flake.nixosModules.sifa.medya.bluetooth =
  { pkgs, ... }:
  {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    environment.systemPackages = with pkgs; [
      bluez
    ];
  };
}
