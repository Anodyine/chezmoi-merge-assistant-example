#!/bin/bash
set -e

echo ">> [Fixer] STARTING..."

# 1. Set Default Subvolume to 5
btrfs subvolume set-default 5 /
echo "   Default subvolume set to 5."

# 2. Get UUID directly from blkid
#    We ask for the device with TYPE="btrfs". 
#    The screenshot proves this works and returns "4ab902fc..."
UUID=$(blkid -t TYPE=btrfs -o value -s UUID | head -n 1)

echo "   UUID from blkid: $UUID"

if [ -z "$UUID" ]; then
    echo "CRITICAL ERROR: blkid could not find a Btrfs partition."
    exit 1
fi

# 3. Patch Limine
CONF="/boot/efi/EFI/arch-limine/limine.conf"

if [ -f "$CONF" ]; then
   echo "   Patching config at $CONF..."
   
   # Fix 1: Generic 'boot():' entries
   sed -i "s|boot():/|uuid($UUID):/@/boot/|g" "$CONF"
   
   # Fix 2: Existing 'uuid(...):/boot/' entries (archinstall default)
   sed -i "s|):/boot/|):/@/boot/|g" "$CONF"
   
   echo "   Success: Limine patched."
else
   echo "CRITICAL ERROR: Config not found at $CONF"
   exit 1
fi

echo ">> SETUP COMPLETE."