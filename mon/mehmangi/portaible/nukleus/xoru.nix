{ ... }:
{
  flake.nixosModules.portaible.xoru =
  { pkgs, ... }:
  {
    # Bootloader.
    boot.loader.grub = {
      enable = true;
      efiSupport = true;
      efiInstallAsRemovable = true;
      device = "nodev"; # Nodev is required for EFI
    };

    boot.loader.systemd-boot.enable = false;
    boot.loader.efi.canTouchEfiVariables = false;

    # Use latest kernel.
    boot.kernelPackages = pkgs.linuxPackages_latest;
  };
}
