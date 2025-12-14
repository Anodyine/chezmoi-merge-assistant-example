#!/bin/bash
set -e

echo ">> [Fixer] STARTING POST-INSTALL BTRFS FIXES..."

# 1. Find the Btrfs Root Partition
ROOT_DEV=$(findmnt -n -o SOURCE /)
echo "   Root Device Detected: $ROOT_DEV"

# 2. Set the Default Subvolume to ID 5 (The True Root)
#    CRITICAL: Do NOT use 'sudo' here. We are already root in the chroot.
echo "   Resetting default subvolume to ID 5..."
btrfs subvolume set-default 5 /

# 3. Verify it worked
NEW_DEFAULT=$(btrfs subvolume get-default /)
echo "   New Default: $NEW_DEFAULT (Target: ID 5)"

# 4. Patch Limine Config (Atomic Fix)
CONF="/boot/efi/limine/limine.conf"

if [ -f "$CONF" ]; then
   echo "   Patching Limine config at $CONF..."
   
   # Get UUID (No sudo)
   UUID=$(blkid -s UUID -o value "$ROOT_DEV")
   
   if [ -z "$UUID" ]; then
       echo "CRITICAL ERROR: Could not detect UUID for $ROOT_DEV"
       exit 1
   fi
   
   echo "   Target UUID: $UUID"
   
   # Replace relative paths with absolute atomic paths
   # FROM: boot():/vmlinuz...
   # TO:   uuid(XYZ):/@/boot/vmlinuz...
   # (We only need one sed command with the 'g' flag)
   sed -i "s|boot():/|uuid($UUID):/@/boot/|g" "$CONF"
   
   echo "   Success: Limine configured for Atomic Rollbacks."
else
   echo "CRITICAL ERROR: Limine config not found at $CONF"
   echo "Is the ESP mounted at /boot/efi?"
   exit 1
fi

echo ">> SETUP COMPLETE."