#!/bin/bash

set -x

if [ -z "$1" ]; then
  echo "Usage: $0 <iso-file>"
  exit 1
fi

if ! command -v qemu-system-x86_64 &> /dev/null; then
  echo "qemu-system-x86_64 could not be found. Please install QEMU."
  exit 1
fi

ISO_FILE=$1
BASE_NAME=$(basename "$ISO_FILE" .iso)
DISK_IMAGE="${BASE_NAME}.qcow2"
DISK_SIZE="50G"
RAM_SIZE="4G"
CPU_CORES=2

if [ ! -f "$DISK_IMAGE" ]; then
  echo "Creating a new virtual disk image ($DISK_IMAGE)..."
  qemu-img create -f qcow2 "$DISK_IMAGE" "$DISK_SIZE"
fi

DISK_SIZE_ACTUAL=$(du -b "$DISK_IMAGE" | cut -f1)

# If the disk image is empty (<1MB = 1024*1024), assume uninitialised & boot from the ISO file.
if [ "$DISK_SIZE_ACTUAL" -le 1048576 ]; then 
  echo "Booting from ISO..."
  BOOT_OPTION="-boot d -cdrom $ISO_FILE"
else
  echo "Booting from the virtual disk image ($DISK_IMAGE)..."
  BOOT_OPTION=""
fi

qemu-system-x86_64 \
  -m "$RAM_SIZE" \
  -smp cores="$CPU_CORES" \
  -hda "$DISK_IMAGE" \
  $BOOT_OPTION \
  -vga qxl \
  -usb -device usb-tablet \
  -net nic -net user \
  -enable-kvm \
  -cpu host