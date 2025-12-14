#!/bin/bash
set -e

echo ">> [Fixer] STARTING..."

# 1. Set Default Subvolume to 5 (Crucial for rollbacks)
btrfs subvolume set-default 5 /
echo "   Default subvolume set to 5."

# 2. Get the Correct UUIDs
#    We grab the Filesystem UUID (for Limine) and PARTUUID (to fix the kernel command line)
#    We use blkid to be 100% sure we get the real values from the disk.
ROOT_UUID=$(blkid -t TYPE=btrfs -o value -s UUID | head -n 1)
ROOT_PARTUUID=$(blkid -t TYPE=btrfs -o value -s PARTUUID | head -n 1)

if [ -z "$ROOT_UUID" ]; then
    echo "CRITICAL ERROR: Could not find Btrfs UUID."
    exit 1
fi

echo "   Filesystem UUID: $ROOT_UUID"
echo "   Partition UUID:  $ROOT_PARTUUID"

# 3. Patch Limine Config
CONF="/boot/efi/EFI/arch-limine/limine.conf"

if [ -f "$CONF" ]; then
   echo "   Patching config at $CONF..."
   
   # --- FIX 1: The Kernel Path (Limine needs to see /@/boot) ---
   # Replace generic 'boot():' with specific 'uuid(...):/@/boot/'
   sed -i "s|boot():/|uuid($ROOT_UUID):/@/boot/|g" "$CONF"
   # Catch existing relative paths
   sed -i "s|):/boot/|):/@/boot/|g" "$CONF"
   
   # --- FIX 2: The Kernel Root (Linux needs the correct Drive) ---
   # Archinstall often writes the wrong PARTUUID. We force it to use the correct one.
   # We replace any 'root=PARTUUID=...' with 'root=PARTUUID=[ACTUAL_PARTUUID]'
   sed -i "s|root=PARTUUID=[^ ]*|root=PARTUUID=$ROOT_PARTUUID|g" "$CONF"
   
   echo "   Success: Limine patched (Path + Root Fixed)."
else
   echo "CRITICAL ERROR: Config not found at $CONF"
   exit 1
fi

echo ">> SETUP COMPLETE."