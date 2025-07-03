{ writeShellScriptBin
, util-linux
, parted
, dosfstools
, e2fsprogs
}: writeShellScriptBin "prepare-nixos-disk" ''
  # Adapted from: https://nixos.wiki/wiki/NixOS_Installation_Guide#Partitioning 
  set -euo pipefail

  if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root."
    exit 1
  fi

  printf "Available block devices:\n\n"
  ${util-linux}/bin/lsblk
  read -p "Device to prepare (this will be wiped!): /dev/" device
  device="/dev/$device"
  echo "You have selected: $device"

  if [ ! -b "$device" ]; then
    echo "Error: $device is not a block device."
    exit 1
  fi

  echo "Partitioning disk with parted..."
  sudo ${parted}/bin/parted -s "$device" mklabel gpt
  sudo ${parted}/bin/parted -s "$device" mkpart primary fat32 1MiB 501MiB
  sudo ${parted}/bin/parted -s "$device" set 1 esp on
  sudo ${parted}/bin/parted -s "$device" mkpart primary ext4 501MiB 100%

  bootpart="''${device}1"
  rootpart="''${device}2"

  echo "Formatting partitions..."
  sudo ${dosfstools}/bin/mkfs.fat -F 32 "$bootpart"
  sudo ${dosfstools}/bin/fatlabel "$bootpart" NIXBOOT
  sudo ${e2fsprogs}/bin/mkfs.ext4 -L NIXROOT "$rootpart"

  echo "Done! Disk is ready for NixOS installation."
''
