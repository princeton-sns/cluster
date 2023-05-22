#!/usr/bin/env bash

set -e

echo "Princeton SNS Cluster Install Script. Hello World!"
echo "=================================================="
echo

if [ "$(id -u)" -ne 0 ]; then
	echo "This script must be run as root!"
	exit 1
fi

# Make sure we're not booted into an EFI system. For now, only BIOS
# boot is supported.
if [ -d /sys/firmware/efi ]; then
	echo "Error: EFI boot is currently supported..."
	exit 1
fi

SWAP_PART_NODE=""
BOOT_PART_NODE=""

function boot_setup_single() {
	echo "Please enter the /dev/ device node name to partition and create a ZFS pool on."
	echo "WARNING: This will destroy all data on the device!"

	read -rp "/dev/" BOOT_DEV_NODE
	if [ ! -b "/dev/$BOOT_DEV_NODE" ]; then
		echo "/dev/$BOOT_DEV_NODE does not exist."
		return
	fi

	# Partition the drive:
	echo "--> Partitioning drive..."
	parted -s -a optimal --script "/dev/$BOOT_DEV_NODE" unit s \
		mklabel gpt \
		disk_set pmbr_boot on \
		mkpart bios_boot 2048 4095 \
		set 1 bios_grub on \
		mkpart boot fat32 4096 2101247 \
		mkpart swap linux-swap 2101248 10489855 \
		mkpart rpool 10489856 "100%"

	# Reload the partition table
	partprobe

	# Format the boot & swap partitions:
	BOOT_PART_NODE="${BOOT_DEV_NODE}2"
	echo "--> Formatting boot partition on /dev/$BOOT_PART_NODE..."
	mkfs.vfat "/dev/$BOOT_PART_NODE"
	SWAP_PART_NODE="${BOOT_DEV_NODE}3"
	echo "--> Formatting swap partition on /dev/$SWAP_PART_NODE..."
	mkswap "/dev/${SWAP_PART_NODE}"

	# Create the ZFS root pool
	echo "--> Creating ZFS root pool \"rpool\""
	zpool create -f \
		-o ashift=12 \
		-o autotrim=on \
		-O acltype=posixacl \
		-O compression=lz4 \
		-O dnodesize=auto \
		-O normalization=formD \
		-O relatime=on \
		-O xattr=sa \
		-O mountpoint=none \
		rpool "/dev/${BOOT_DEV_NODE}4"
}

function boot_config_select() {
	echo "This system has the following drives attached:"
	lsblk
	read -rp "Setup a (s)ingle boot drive, (r)AID-1 ZFS pool, (m)anual config or (q)uit? > " BOOT_CONFIG_TYPE
	if [ "$BOOT_CONFIG_TYPE" == "s" ]; then
		RET=0; boot_setup_single || RET=$?
		return $RET
	elif [ "$BOOT_CONFIG_TYPE" == "r" ]; then
		echo "RAID-1 boot setup is not yet supported."
		return 1
	elif [ "$BOOT_CONFIG_TYPE" == "m" ]; then
		echo "Manual configuration selected. Interrupt this script with C-z."
		echo "Set up the boot partition and root ZFS pool (named rpool)."
		echo "When done, bring the script into foreground with fg and press ENTER."
		echo "We will then prompt for the boot and (if created) swap part device nodes."
		read -rp "> PRESS ENTER WHEN READY"
		read -rp "Boot disk device node > /dev/" BOOT_DEV_NODE
		read -rp "Boot part device node > /dev/" BOOT_PART_NODE
		read -rp "Swap part device node (leave empty if no swap) > /dev/" SWAP_PART_NODE
	elif [ "$BOOT_CONFIG_TYPE" == "q" ]; then
		exit 0
	else
		echo "Unknown command, please try again. Enter \"q\" to quit."
		return 1
	fi
}

BOOT_CONFIG_DONE=0
while [ $BOOT_CONFIG_DONE -eq 0 ]; do
	if boot_config_select; then
		if [ ! -b "/dev/$BOOT_PART_NODE" ]; then
			echo "Boot partition /dev/$BOOT_PART_NODE does not appear to be a block device."
		elif ! zpool list -H rpool > /dev/null; then
			echo "ZFS pool \"rpool\" not found."
		else
			if [ "$(zfs list -H rpool -d1 | wc -l)" -gt 1 ]; then
			echo "Warning: ZFS pool \"rpool\" does not seem to be empty."
			fi
			BOOT_CONFIG_DONE=1
		fi
	else
		echo "Whoops, that didn't work. Please try again..."
	fi
done

function zfs_create_filesystems() {
	# Create the ZFS file systems. This is unified across different boot config types:
	zfs create rpool/local
	zfs create -o mountpoint=legacy rpool/local/nix
	zfs create rpool/local/transient
	zfs create -o mountpoint=legacy rpool/local/transient/root
	zfs snapshot rpool/local/transient/root@blank
	zfs create rpool/state
	zfs create -o mountpoint=legacy rpool/state/system
	zfs create rpool/state/home
}

read -rp "About to create ZFS file systems. Continue? (Y/(s)kip/(q)uit)" ZFS_CREATE_FS_INPUT
if [ "$ZFS_CREATE_FS_INPUT" == "q" ]; then
	echo "Goodbye!"
	exit 0
elif [ "$ZFS_CREATE_FS_INPUT" == "s" ]; then
	echo "Skipping file system creation."
else
	echo "Creating ZFS file systems..."
	zfs_create_filesystems
fi

function fs_mount() {
	# Mount the root file system, boot partition and state volumes:
	mkdir -p /mnt
	mount -t zfs rpool/local/transient/root /mnt
	mkdir -p /mnt/boot /mnt/nix /mnt/etc /mnt/var/state
	mount "/dev/$BOOT_PART_NODE" /mnt/boot
	mount -t zfs rpool/local/nix /mnt/nix
	mount -t zfs rpool/state/system /mnt/var/state
	mkdir -p /mnt/var/state/nixos
	ln -s ../var/state/nixos /mnt/etc/nixos
}

read -rp "About to mount file systems. Continue? (Y/(s)kip/(q)uit)" FS_MOUNT_INPUT
if [ "$FS_MOUNT_INPUT" == "q" ]; then
	echo "Goodbye!"
	exit 0
elif [ "$FS_MOUNT_INPUT" == "s" ]; then
	echo "Not mounting file systems."
else
	echo "Mounting file systems..."
	fs_mount
fi

HOSTNAME_CORRECT=0
while [ $HOSTNAME_CORRECT -eq 0 ]; do
	read -rp "Enter this machine's hostname: " MACHINE_HOSTNAME
	echo "Got the hostname as \"$MACHINE_HOSTNAME\", creating configuration as \"$MACHINE_HOSTNAME.nix\"."
	read -rp "Is this correct (y/N)? " HOSTNAME_CORRECT_INPUT
	if [ "$HOSTNAME_CORRECT_INPUT" == "y" ]; then
		HOSTNAME_CORRECT=1
	fi
done

echo "--> Cloning the SNS cluster configuration to /mnt/etc/nixos and"
echo "	creating a symlink for configuration.nix to machines/$MACHINE_HOSTNAME.nix"
git clone "$(readlink -f .)" /mnt/etc/nixos/
ln -s "./machines/$MACHINE_HOSTNAME.nix" /mnt/etc/nixos/configuration.nix

TEMPLATE_CORRECT=0
while [ $TEMPLATE_CORRECT -eq 0 ]; do
	echo "You can preprovision this machine with a cluster-config template."
	echo "Which template would you like to use?"
	for TMPL in ./templates/*; do
		echo "- $(basename "$TMPL")"
	done
	read -rp "Enter a template filename or \"quit\" > " TEMPLATE_FILE
	if [ "$TEMPLATE_FILE" == "quit" ]; then
		echo "Goodbye!"
		exit 0
	elif [ -f "./templates/$TEMPLATE_FILE" ]; then
		TEMPLATE_CORRECT=1
	else
		echo "Could not find template \"$TEMPLATE_FILE\", please try again."
	fi
done

TMPLSTR_NIXOS_VERSION="$(nixos-version | sed 's/^\([[:digit:]]\+\.[[:digit:]]\+\).*$/\1/')"
export TMPLSTR_NIXOS_VERSION

TMPLSTR_HOST_ID="$(head -c8 < /etc/machine-id)"
export TMPLSTR_HOST_ID
TMPLSTR_HOSTNAME="$MACHINE_HOSTNAME"
export TMPLSTR_HOSTNAME
TMPLSTR_UPLINK_IFACE="$(ip -o route get 8.8.8.8 | sed 's/^.* dev \([[:alnum:]]\+\) .*$/\1/')"
export TMPLSTR_UPLINK_IFACE

TMPLSTR_BOOT_DISK_NODE="/dev/$BOOT_DEV_NODE"
for NODE in /dev/disk/by-id/*; do
	if [ "$(readlink -f "$NODE")" == "/dev/$BOOT_DEV_NODE" ]; then
		echo "$NODE matches for bootdev!"
		TMPLSTR_BOOT_DISK_NODE="$(readlink -f "$NODE")"
	fi
done
if [ "$TMPLSTR_BOOT_DISK_NODE" == "/dev/$BOOT_DEV_NODE" ]; then
	echo "Warning: could not resolve the boot device node to a device id."
	echo "This will still work, but might be brittle when disk letter assignments change."
fi
export TMPLSTR_BOOT_DISK_NODE

TMPLSTR_BOOT_PART_UUID=""
for NODE in /dev/disk/by-uuid/*; do
	if [ "$(readlink -f "$NODE")" == "/dev/$BOOT_PART_NODE" ]; then
		TMPLSTR_BOOT_PART_UUID="$(basename "$NODE")"
	fi
done
if [ "$TMPLSTR_BOOT_PART_UUID" == "" ]; then
	echo "Failed to resolve boot partition to UUID!"
	exit 1
fi
export TMPLSTR_BOOT_PART_UUID

TMPLSTR_NULLABLE_SWAP_PART_UUID=""
if [ "$SWAP_PART_NODE" != "" ]; then
	for NODE in /dev/disk/by-uuid/*; do
		if [ "$(readlink -f "$NODE")" == "/dev/$SWAP_PART_NODE" ]; then
			TMPLSTR_NULLABLE_SWAP_PART_UUID="\"$(basename "$NODE")\""
		fi
	done
	if [ "$TMPLSTR_NULLABLE_SWAP_PART_UUID" == "" ]; then
		echo "Failed to resolve boot partition to UUID!"
		exit 1
	fi
else
	TMPLSTR_NULLABLE_SWAP_PART_UUID="null"
fi
export TMPLSTR_NULLABLE_SWAP_PART_UUID

envsubst < "./templates/$TEMPLATE_FILE" > "/mnt/etc/nixos/machines/$MACHINE_HOSTNAME.nix"
echo "Templated /mnt/etc/nixos/machines/$MACHINE_HOSTNAME.nix. Goodbye!"
