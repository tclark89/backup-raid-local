#!/bin/bash
set -e

# Set folder names
time_stamp=$(date '+%Y-%m-%d_%H-%M-%S')

raid_live='/mnt/RAID'
raid_backup='/mnt/raid_backup'
#raid_backup='/mnt/offline_backup'

raid_backup_snapshot_dir=${raid_backup}/snapshots
raid_backup_snapshot_dir_new=/mnt/snapshots


meagan_dir=/mnt/meagan
virtual_machines_dir=/mnt/virtual_machines

public_snap=${raid_backup_snapshot_dir}/public_${time_stamp}
tyler_snap=${raid_backup_snapshot_dir}/tyler_${time_stamp}
meagan_snap=${raid_backup_snapshot_dir}/meagan_${time_stamp}
#virtual_machines_snap=${raid_live_snapshot_dir}/virtual_machines_${time_stamp}
#torrents_snap=${raid_live_snapshot_dir}/torrents_${time_stamp}
#time_machine_snap=${raid_live_snapshot_dir}/time_machine_${time_stamp}

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
#btrfs subvolume snapshot -r ${raid_backup}/virtual_machines $virtual_machines_snap
#btrfs subvolume snapshot -r ${raid_backup}/torrents $torrents_snap
#btrfs subvolume snapshot -r /mnt/timemachine $time_machine_snap


# Rsync
rsync \
	${raid_live}/public/ \
	${raid_backup}/public/ \
	-aWSAXEH \
	-vh \
	--delete-delay \
	--exclude='.snaphots' \
	--exclude-from=${raid_live}/public/public-excludes 

rsync \
	${raid_live}/tyler/ \
	${raid_backup}/tyler/ \
	-aWSAXEH \
	-vh \
	--delete-delay \
	--exclude='.snaphots' \
	--exclude-from=${raid_live}/tyler/tyler-excludes 

rsync \
	$meagan_dir \
	${raid_backup}/meagan/ \
	-aWSAXEH \
	-vh \
	--delete-delay \
	--exclude='.snaphots' \
	--exclude-from=${meagan_dir}/meagan-excludes 

rsync \
	$virtual_machines_dir \
	${raid_backup}/virtual_machines/ \
	-aWSAXEH \
	-vh \
	--delete-delay \
	--exclude='.snaphots' \
	--exclude-from=${virtual_machines_dir}/virtual_machines-excludes 

rsync \
	${raid_live}/torrents/ \
	${raid_backup}/torrents/ \
	-aWSAXEH \
	-vh \
	--delete-delay \
	--exclude='*.part' \
	--exclude-from=${raid_live}/torrents/torrents-excludes \
	--delete-excluded

rsync \
	/mnt/RAID/timemachine \
	${raid_backup}/timemachine \
	-aWSAXEH \
	-vh \
	--delete-delay \
	--exclude='lost+found'


# FIGURE OUT UNMOUNT LOGIC
if ! $backup_mounted 
then
	/usr/bin/umount $raid_backup
fi
