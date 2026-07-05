{ ... }:
{
  flake.nixosModules.ayse.nukleus.disko =
  { ... }:
  {
    fileSystems."/nix".neededForBoot = true;
    fileSystems."/persistent".neededForBoot = true;

    disko.devices.nodev = {
      # Root tmpfs. 25% of 16G RAM = 4G, enough for /, /home, /tmp, /var/tmp,
      # and transient runtime state. Real home data lives on /persistent and is
      # bind-mounted in by the preservation module.
      "/" = {
        fsType = "tmpfs";
        mountOptions = [
          "size=25%"
          "mode=755"
        ];
      };
    };

    # Fast NVMe SSD: boot, swap, and the Nix store.
    disko.devices.disk.main = {
      device = "/dev/disk/by-id/nvme-SSSTC_CL1-4D256_SS0X49598L1BR0AM50LN_1";
      type = "disk";

      content.type = "gpt";

      content.partitions.esp = {
        name = "ESP";
        size = "1G";
        type = "EF00";

        content = {
          type = "filesystem";
          format = "vfat";
          mountpoint = "/boot";
        };
      };

      content.partitions.swap = {
        size = "16G";

        content = {
          type = "swap";
          resumeDevice = true;
        };
      };

      content.partitions.root = {
        name = "root";
        size = "100%";

        content = {
          type = "btrfs";
          extraArgs = [ "-f" ];

          subvolumes = {
            "/nix" = {
              mountOptions = [ "subvol=nix" "noatime" ];
              mountpoint = "/nix";
            };
          };
        };
      };
    };

    # Large SATA HDD: persistent state.
    #
    # TODO: The filesystem was originally created without subvolumes. To add
    # an @persistent subvolume later, boot from a live USB and run:
    #
    #   mount /dev/disk/by-id/ata-WDC_WD10SPZX-75Z10T2_WX21E78E5Z24-part1 /mnt
    #   btrfs subvolume create /mnt/@persistent
    #   mv /mnt/* /mnt/@persistent/ 2>/dev/null || true
    #   # Do NOT move the @persistent directory into itself.
    #   umount /mnt
    #
    # Then change this content block to type = "btrfs" with subvolumes.
    disko.devices.disk.home = {
      device = "/dev/disk/by-id/ata-WDC_WD10SPZX-75Z10T2_WX21E78E5Z24";
      type = "disk";

      content.type = "gpt";

      content.partitions.home = {
        name = "home";
        size = "100%";

        content = {
          type = "filesystem";
          format = "btrfs";
          mountpoint = "/persistent";
          mountOptions = [ "compress=zstd" "noatime" ];
        };
      };
    };
  };
}
