#!/bin/bash
set -e 

echo ">> [Fixer] STARTING..."

# 1. Set Default Subvolume to 5 (Crucial Step)
#    We do this on the mount point "/", so we don't need the device name yet.
btrfs subvolume set-default 5 /
echo "   Default subvolume set to 5."

# 2. Get UUID Safely (No Parsing)
#    We ask findmnt for the UUID column directly. No 'cut', no brackets.
UUID=$(findmnt -n -o UUID /)

#    Fallback: If that returns empty, we strip brackets using bash native expansion (safer than cut)
if [ -z "$UUID" ]; then
    RAW=$(findmnt -n -o SOURCE /)
    CLEAN_DEV=${RAW%%[*} # Removes everything after '['
    UUID=$(blkid -s UUID -o value "$CLEAN_DEV")
fi

if [ -z "$UUID" ]; then
    echo "CRITICAL ERROR: Could not find UUID."
    exit 1
fi

echo "   Target UUID: $UUID"

# 3. Patch Limine
CONF="/boot/efi/EFI/arch-limine/limine.conf"

if [ -f "$CONF" ]; then
   # Fix 1: Generic 'boot():' -> 'uuid(ID):/@/boot/'
   sed -i "s|boot():/|uuid($UUID):/@/boot/|g" "$CONF"
   
   # Fix 2: Existing 'uuid(...):/boot/' -> 'uuid(...):/@/boot/'
   sed -i "s|):/boot/|):/@/boot/|g" "$CONF"
   
   echo "   Success: Limine patched."
else
   echo "CRITICAL ERROR: Config not found at $CONF"
   exit 1
fi

echo ">> SETUP COMPLETE."