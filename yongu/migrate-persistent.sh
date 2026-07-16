#!/usr/bin/env bash
# Automated live migration script for the /persistent NVMe SSD transition.
# This script mounts the SSD root, creates the subvolume, syncs persistent data,
# and prepares the boot loader for the next boot.

set -euo pipefail

# Ensure the script is run with root privileges
if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root (or via sudo)." >&2
   exit 1
fi

echo "=== Ephemeral System Refactor: Live Migration to SSD ==="

SSD_DEV="/dev/nvme0n1p3"
HDD_MOUNT="/persistent"
TMP_MOUNT="/tmp/ssd-top-migration"

# Check if SSD device partition exists
if [[ ! -e "$SSD_DEV" ]]; then
    echo "Error: NVMe SSD partition $SSD_DEV not found!" >&2
    exit 1
fi

# Clean up any stale mounts
if mountpoint -q "$TMP_MOUNT" 2>/dev/null; then
    echo "Unmounting stale migration mount..."
    umount "$TMP_MOUNT"
fi
mkdir -p "$TMP_MOUNT"

# 1. Mount the top-level SSD subvolume
echo "Mounting SSD top-level ($SSD_DEV) to $TMP_MOUNT..."
mount -o subvolid=5 "$SSD_DEV" "$TMP_MOUNT"

# Check if @persistent already exists on the SSD
if [[ -d "$TMP_MOUNT/@persistent" ]]; then
    echo "Warning: @persistent subvolume already exists on the NVMe SSD."
    read -p "Do you want to delete the existing SSD @persistent and start fresh? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Deleting old @persistent subvolume..."
        btrfs subvolume delete "$TMP_MOUNT/@persistent"
        echo "Creating new @persistent subvolume..."
        btrfs subvolume create "$TMP_MOUNT/@persistent"
    else
        echo "Using existing @persistent subvolume and performing an incremental sync."
    fi
else
    echo "Creating new @persistent subvolume..."
    btrfs subvolume create "$TMP_MOUNT/@persistent"
fi

# 2. Sync files from active /persistent (HDD) to the SSD subvolume
# Exclude large bulk storage XDG directories (Downloads, Music, Videos)
echo "Syncing data from HDD ($HDD_MOUNT) to SSD (@persistent)..."
rsync -avHAX --progress \
  --exclude='home/eter/Downloads' \
  --exclude='home/eter/Music' \
  --exclude='home/eter/Videos' \
  "$HDD_MOUNT/" "$TMP_MOUNT/@persistent/"

# 3. Unmount and clean up
echo "Unmounting SSD top-level..."
umount "$TMP_MOUNT"
rmdir "$TMP_MOUNT"

# 4. Run nixos-rebuild boot to configure the next boot
echo "Building new configuration and updating the boot loader..."
nixos-rebuild boot --flake /persistent/nixos

echo "=========================================================="
echo "Migration complete and boot configuration updated!"
echo "Please reboot your system now to apply the changes."
echo "=========================================================="
echo "POST-REBOOT CLEANUP:"
echo "Once you have successfully booted into the new system, you can free"
echo "up space on the HDD (which will be mounted at /storage) by running:"
echo
echo "  sudo rm -rf /storage/etc /storage/var /storage/nixos /storage/home/eter/.config /storage/home/eter/.local /storage/home/eter/.gemini /storage/home/eter/.ssh /storage/home/eter/Desktop /storage/home/eter/Documents /storage/home/eter/Pictures /storage/home/eter/Projects /storage/home/eter/Public /storage/home/eter/Templates"
echo "=========================================================="
