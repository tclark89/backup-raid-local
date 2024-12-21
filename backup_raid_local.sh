#!/bin/bash
set -e

# Set folder names
time_stamp=$(date '+%Y-%m-%d_%H-%M-%S')

raid_live='/mnt/RAID'
raid_backup='/mnt/raid_backup'

raid_backup_snapshot_dir=${raid_backup}/snapshots

meagan_dir=/mnt/meagan/
virtual_machines_dir=/mnt/virtual_machines/

public_snap=${raid_backup_snapshot_dir}/public_${time_stamp}
tyler_snap=${raid_backup_snapshot_dir}/tyler_${time_stamp}
meagan_snap=${raid_backup_snapshot_dir}/meagan_${time_stamp}

# FIGURE OUT MOUNT LOGIC/FLOW
#mount /mnt/raid_backup
#
if grep -qs '/mnt/raid_backup ' /proc/mounts
#if grep -qs '/mnt/offline_backup ' /proc/mounts
then
	backup_mounted=true
else 
	backup_mounted=false
fi

if ! $backup_mounted
then
	/usr/bin/mount $raid_backup
#	exit 1
fi


# ONCE IT'S ALL MOUNTED AND GOOD
# create snapshots. 
btrfs subvolume snapshot -r ${raid_backup}/public $public_snap
btrfs subvolume snapshot -r ${raid_backup}/tyler $tyler_snap
btrfs subvolume snapshot -r ${raid_backup}/meagan $meagan_snap


# Rsync
rsync \
	/mnt/public/ \
	${raid_backup}/public/ \
	-aAXEH \
	-vh \
	--delete-delay \
	--exclude='.snaphots' \
	--exclude-from=/mnt/public/public-excludes 

rsync \
	/mnt/tyler/ \
	${raid_backup}/tyler/ \
	-aAXEH \
	-vh \
	--delete-delay \
	--exclude='.snaphots' \
	--exclude-from=/mnt/tyler/tyler-excludes 

rsync \
	$meagan_dir \
	${raid_backup}/meagan/ \
	-aAXEH \
	-vh \
	--delete-delay \
	--exclude='.snaphots' \
	--exclude-from=${meagan_dir}/meagan-excludes 

rsync \
	$virtual_machines_dir \
	${raid_backup}/virtual_machines/ \
	-aAXEH \
	-vh \
	--delete-delay \
	--exclude='.snaphots' \
	--exclude-from=${virtual_machines_dir}/virtual_machines-excludes 

rsync \
	/mnt/torrents/ \
	${raid_backup}/torrents/ \
	-aAXEH \
	-vh \
	--delete-delay \
	--exclude='*.part' \
	--exclude-from=/mnt/torrents/torrents-excludes \
	--delete-excluded

rsync \
	/mnt/RAID/timemachine/ \
	${raid_backup}/timemachine/ \
	-aAXEH \
	-vh \
	--delete-delay 

rsync \
	/srv/docker/nextcloud/html/ \
	${raid_backup}/nextcloud/html/ \
	-aAXEHh \
	--delete-delay 

rsync \
	/srv/docker/nextcloud/data/ \
	${raid_backup}/nextcloud/data/ \
	-aAXEHh \
	--delete-delay 


# FIGURE OUT UNMOUNT LOGIC
if ! $backup_mounted 
then
	/usr/bin/umount $raid_backup
fi
