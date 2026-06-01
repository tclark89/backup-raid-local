#!/bin/bash
set -e

# Set folder names
#time_stamp=$(date '+%Y-%m-%d_%H-%M-%S')

#raid_live='/mnt/RAID'
raid_backup='/mnt/raid_backup'
public_backup='mnt/public_backup'
personal_backup='/mnt/personal_backup'

#raid_backup_snapshot_dir=${raid_backup}/snapshots

meagan_dir=/mnt/meagan/
virtual_machines_dir=/mnt/virtual_machines/

#public_snap=${raid_backup_snapshot_dir}/public_${time_stamp}
#tyler_snap=${raid_backup_snapshot_dir}/tyler_${time_stamp}
#meagan_snap=${raid_backup_snapshot_dir}/meagan_${time_stamp}

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
# create snapshots:
btrbk -c /etc/btrbk/btrbk_raid_backup.conf run -v

# Rsync directories
# Public mergerfs pool
# RAID Drives
rsync \
	/mnt/public/ \
	${raid_backup}/public/ \
	-aAXEH \
	-vh \
	--delete-delay \
	--exclude='.snaphots' \
	--exclude-from=/mnt/public/public-excludes 

# /mnt/tyler 
# Original RAID drives
rsync \
	/mnt/tyler/ \
	${raid_backup}/tyler/ \
	-aAXEH \
	-vh \
	--delete-delay \
	--exclude='.snaphots' \
	--exclude-from=/mnt/tyler/tyler-excludes 

# Personal Backup Drive
rsync \
	/mnt/tyler/ \
	${personal_backup}/tyler/ \
	-aAXEH \
	-vh \
	--delete-delay \
	--exclude='.snaphots' \
	--exclude-from=/mnt/tyler/tyler-excludes 

/mnt/meagan
# Original RAID drives
rsync \
	$meagan_dir \
	${raid_backup}/meagan/ \
	-aAXEH \
	-vh \
	--delete-delay \
	--exclude='.snaphots' \
	--exclude-from=${meagan_dir}/meagan-excludes 

# Personal Backup Drive
rsync \
	$meagan_dir \
	${personal_backup}/meagan/ \
	-aAXEH \
	-vh \
	--delete-delay \
	--exclude='.snaphots' \
	--exclude-from=${meagan_dir}/meagan-excludes 

# /mnt/torrents
# Original RAID drives
rsync \
	/mnt/torrents/ \
	${raid_backup}/torrents/ \
	-aAXEH \
	-vh \
	--delete-delay \
	--exclude='*.part' \
	--exclude-from=/mnt/torrents/torrents-excludes \
	--delete-excluded

# Personal Backup Drive
rsync \
	/mnt/torrents/ \
	${personal_backup}/torrents/ \
	-aAXEH \
	-vh \
	--delete-delay \
	--exclude='*.part' \
	--exclude-from=/mnt/torrents/torrents-excludes \
	--delete-excluded

# Backups folder
# Original RAID drives
rsync \
	/mnt/backups/ \
	${raid_backup}/backups/ \
	-axxAXEH \
	-vh \
	--exclude='fileserver/snapshots' \
	--delete-delay 

# Personal Backup Drive
rsync \
	/mnt/backups/ \
	${personal_backup}/backups/ \
	-axxAXEH \
	-vh \
	--exclude='fileserver/snapshots' \
	--delete-delay 




# FIGURE OUT UNMOUNT LOGIC
if ! $backup_mounted 
then
	/usr/bin/umount $raid_backup
fi
