#!/bin/bash
set -e # Exit immediately if a command fails

echo ">> [Fixer] STARTING..."

# 1. Set Default Subvolume to 5 (This always works on the path)
btrfs subvolume set-default 5 /
echo "   Default subvolume set to 5."

# 2. Get UUID from /etc/fstab (Safe & Reliable)
#    We look for the line where the mount point is exactly "/"
#    Example line: UUID=1234-5678 / btrfs ...
UUID=$(awk '$2 == "/" {print $1}' /etc/fstab | cut -d= -f2)

echo "   UUID from fstab: $UUID"

if [ -z "$UUID" ]; then
    echo "CRITICAL ERROR: Could not find UUID in /etc/fstab"
    # Fallback: Try to read it from the existing Limine config
    # This grabs the UUID from the first 'uuid(...)' pattern found in the file
    CONF="/boot/efi/EFI/arch-limine/limine.conf"
    if [ -f "$CONF" ]; then
         echo "   Attempting to rescue UUID from limine.conf..."
         UUID=$(grep -oP 'uuid\(\K[^\)]+' "$CONF" | head -n 1)
         echo "   Rescued UUID: $UUID"
    fi
fi

if [ -z "$UUID" ]; then
    echo "FAILED: No UUID found. Cannot patch Limine."
    exit 1
fi

# 3. Patch Limine
CONF="/boot/efi/EFI/arch-limine/limine.conf"

if [ -f "$CONF" ]; then
   echo "   Patching config at $CONF..."
   
   # Fix 1: Generic 'boot():' entries -> 'uuid(ID):/@/boot/'
   sed -i "s|boot():/|uuid($UUID):/@/boot/|g" "$CONF"
   
   # Fix 2: Existing 'uuid(...):/boot/' entries (The archinstall default)
   # We simply inject /@/ into the path
   sed -i "s|):/boot/|):/@/boot/|g" "$CONF"
   
   echo "   Success: Limine patched."
else
   echo "CRITICAL ERROR: Config not found at $CONF"
   exit 1
fi

echo ">> SETUP COMPLETE."