#!/bin/bash
# We turn off 'set -e' for the detection phase so it doesn't crash if one command misses
set -x

echo ">> [Fixer] STARTING..."

# 1. Find Root Device using 'df' (More reliable in chroot)
#    df / usually prints:
#    Filesystem     ...
#    /dev/nvme0n1p2 ...
ROOT_DEV=$(df / | tail -n 1 | awk '{print $1}')

# Clean up any potential brackets (just in case)
ROOT_DEV=$(echo "$ROOT_DEV" | cut -d'[' -f1)

echo "   Detected Device: $ROOT_DEV"

# 2. Get UUID
UUID=$(blkid -s UUID -o value "$ROOT_DEV")
echo "   UUID: $UUID"

if [ -z "$UUID" ]; then
    echo "CRITICAL ERROR: Could not find UUID for device."
    exit 1
fi

# 3. Set Default Subvolume
#    (Re-enable strict error checking now)
set -e
btrfs subvolume set-default 5 /
echo "   Default subvolume set to 5."

# 4. Patch Limine
CONF="/boot/efi/EFI/arch-limine/limine.conf"

if [ -f "$CONF" ]; then
   # Fix 1: Generic entries
   sed -i "s|boot():/|uuid($UUID):/@/boot/|g" "$CONF"
   # Fix 2: Existing partial entries
   sed -i "s|):/boot/|):/@/boot/|g" "$CONF"
   
   echo "   Success: Limine patched."
else
   echo "CRITICAL ERROR: Config not found at $CONF"
   exit 1
fi

echo ">> SETUP COMPLETE."