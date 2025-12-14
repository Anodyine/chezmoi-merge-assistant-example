#!/bin/bash
set -e

echo ">> [Fixer] STARTING POST-INSTALL BTRFS FIXES..."

# 1. Find the Btrfs Root Partition
ROOT_DEV=$(findmnt -n -o SOURCE / | cut -d'[' -f1)
echo "   Root Device Detected: $ROOT_DEV"

# 2. Set Default Subvolume to ID 5
echo "   Resetting default subvolume to ID 5..."
btrfs subvolume set-default 5 /

# 3. Patch Limine Config
CONF="/boot/efi/EFI/arch-limine/limine.conf"

if [ -f "$CONF" ]; then
   echo "   Found Limine config at: $CONF"
   
   # Get UUID
   UUID=$(blkid -s UUID -o value "$ROOT_DEV")
   
   if [ -z "$UUID" ]; then
       echo "CRITICAL ERROR: Could not detect UUID."
       exit 1
   fi
   
   echo "   Target UUID: $UUID"
   
   # Fix 1: Handle 'boot():' protocol entries (if any)
   sed -i "s|boot():/|uuid($UUID):/@/boot/|g" "$CONF"
   
   # Fix 2: Handle existing UUID entries pointing to the wrong relative path
   sed -i "s|):/boot/|):/@/boot/|g" "$CONF"
   
   echo "   Success: Limine configured."
else
   echo "CRITICAL ERROR: Config not found at $CONF"
   exit 1
fi