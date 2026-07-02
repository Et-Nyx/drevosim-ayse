{
  fileSystems."/nix".neededForBoot = true;
  fileSystems."/persistent".neededForBoot = true;

  disko.devices.nodev = {
    "/" = {
      fsType = "tmpfs";
      mountOptions = [
        "size=25%"
        "mode=755"
      ];
    };
  };

  # NixOS system disk (SSD).
  disko.devices.disk.main = {
    device = "/dev/nvme0n1"; # MAKE SURE TO SELECT CORRECT DISK HERE
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
        extraArgs = ["-f"];

        subvolumes = {
          "/persistent" = {
            mountOptions = ["subvol=persistent" "noatime"];
            mountpoint = "/persistent";
          };

          "/nix" = {
            mountOptions = ["subvol=nix" "noatime"];
            mountpoint = "/nix";
          };
        };
      };
    };
  };

  # Home directories disk (HD).
  disko.devices.disk.home = {
    device = "/dev/sda"; # MAKE SURE TO SELECT CORRECT DISK HERE
    type = "disk";

    content.type = "gpt";

    content.partitions.home = {
      name = "home";
      size = "100%";

      content = {
        type = "filesystem";
        format = "btrfs";
        mountpoint = "/home";
        mountOptions = ["compress=zstd" "noatime"];
      };
    };
  };
}
