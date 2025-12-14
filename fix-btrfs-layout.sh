#!/bin/bash
set -e

echo ">> [Fixer] STARTING POST-INSTALL BTRFS FIXES..."

# 1. Find the Btrfs Root Partition
ROOT_DEV=$(findmnt -n -o SOURCE /)
echo "   Root Device Detected: $ROOT_DEV"

# 2. Set the Default Subvolume to ID 5 (The True Root)
#    This makes the file structure 'Atomic-Ready'
echo "   Resetting default subvolume to ID 5..."
btrfs subvolume set-default 5 /

# 3. Patch Limine Config
CONF="/boot/efi/EFI/arch-limine/limine.conf"

if [ -f "$CONF" ]; then
   echo "   Found Limine config at: $CONF"
   
   # Get UUID of the root partition
   UUID=$(blkid -s UUID -o value "$ROOT_DEV")
   
   if [ -z "$UUID" ]; then
       echo "CRITICAL ERROR: Could not detect UUID for $ROOT_DEV"
       exit 1
   fi
   
   echo "   Target UUID: $UUID"
   
   # Apply the Atomic Path Fix
   # Replaces: boot():/vmlinuz-linux
   # With:     uuid(YOUR_UUID):/@/boot/vmlinuz-linux
   sed -i "s|boot():/|uuid($UUID):/@/boot/|g" "$CONF"
   
   echo "   Success: Limine configured for Atomic Rollbacks."
else
   echo "CRITICAL ERROR: Limine config NOT found at $CONF"
   exit 1
fi

echo ">> SETUP COMPLETE."