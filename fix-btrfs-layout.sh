#!/bin/bash
set -e
set -x  # ENABLE DEBUGGING: Prints every command as it runs

echo ">> [Fixer] STARTING POST-INSTALL BTRFS FIXES..."

# 1. Find the Btrfs Root Partition
#    We use 'cut' to strip the btrfs subvolume brackets "[/@]" 
#    that caused the previous script to crash at blkid.
RAW_SOURCE=$(findmnt -n -o SOURCE /)
ROOT_DEV=$(echo "$RAW_SOURCE" | cut -d'[' -f1)

echo "   Raw Source: $RAW_SOURCE"
echo "   Clean Device: $ROOT_DEV"

# 2. Set Default Subvolume (ID 5)
btrfs subvolume set-default 5 /

# 3. Patch Limine Config
CONF="/boot/efi/EFI/arch-limine/limine.conf"

if [ -f "$CONF" ]; then
   # Get UUID (This will now succeed because ROOT_DEV is clean)
   UUID=$(blkid -s UUID -o value "$ROOT_DEV")
   
   if [ -z "$UUID" ]; then
       echo "CRITICAL ERROR: UUID is empty."
       exit 1
   fi
   
   echo "   Target UUID: $UUID"
   
   # Apply Atomic Fixes
   # Fix 1: Generic entries
   sed -i "s|boot():/|uuid($UUID):/@/boot/|g" "$CONF"
   # Fix 2: Existing partial entries
   sed -i "s|):/boot/|):/@/boot/|g" "$CONF"
   
   echo "   Success: Limine configured."
else
   echo "CRITICAL ERROR: Config not found at $CONF"
   exit 1
fi

echo ">> SETUP COMPLETE."