{ ... }:
{
  flake.nixosModules.ayse.nukleus.disko =
  { ... }:
  {
    fileSystems."/".neededForBoot = true;
    fileSystems."/nix".neededForBoot = true;

    # Fast NVMe SSD: root, boot, swap, and the Nix store.
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
            # disko generates the subvol= option itself; only extra options
            # belong here (avoids duplicated subvol keys in fstab).
            "@root" = {
              mountOptions = [ "noatime" "compress=zstd" ];
              mountpoint = "/";
            };
            "/nix" = {
              mountOptions = [ "noatime" ];
              mountpoint = "/nix";
            };
          };
        };
      };
    };

    # Large SATA HDD: bulk user data.
    #
    # NOTE: disko is only ever run at format time. The NVMe filesystem still
    # carries the @persistent-ro-backup snapshot of the pre-migration state;
    # it is not mounted and can be deleted manually once it is no longer
    # wanted.
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
          mountpoint = "/storage";
          mountOptions = [ "compress=zstd" "noatime" ];
        };
      };
    };
  };
}
