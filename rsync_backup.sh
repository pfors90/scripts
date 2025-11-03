#!/bin/bash

### very specific use case, basically to avoid me accidentally wiping
### another backup drive in the process of trying to update backups

### file is intended to be stored in the root dir of a backup drive and executed from there
### config options below specify values to be used later in the file. adjust them for each 
### drive as necessary

### the script will CD to the backup directory, output the results of an rsync dry run with
### the user-specified arguments, on the user specified directories

### if the dry-run results look good to the user, then rsync will be called and the results
### output to a file and the terminal

### IMPORTANT
### place this script on a backup drive and run it from there
### all backup drives paths are interpreted relative to the location of this script

### NOTE
### written specifically for unraid, you may need to change SHARE_BASE further down

###################################
### START CONFIGURATION OPTIONS ###
######## EDIT AS NECESSARY ########
###################################

# DRIVE-SPECIFIC DECLARATIONS
BACKUP_NAME="INSERT NAME"
SHARE_NAME="INSERT NAME"

INCLUDE_GLOB='*' # glob representation of what files/folders to include from the share

# ARGUMENTS FOR RSYNC RUN
RSYNC_ARGS=(-avh --delete-before --size-only -P --include="$INCLUDE_GLOB")

###################################
###################################

DATE=$(date +"%Y%m%d")

MOUNT_POINT="$(dirname $0)"

# filepaths
BACKUP_BASE="$MOUNT_POINT/$SHARE_NAME"
SHARE_BASE="/mnt/user/$SHARE_NAME"
LOG_DIR="$MOUNT_POINT/logs"
mkdir -p "$LOG_DIR"
SCRIPT_LOG="$LOG_DIR/log.log"
BACKUP_LOG="$LOG_DIR/$(DATE)_backup.log"

echo "[$DATE]" >> "$SCRIPT_LOG"
echo "BACKUP DRIVE: $BACKUP_NAME" >> "$SCRIPT_LOG"
echo "SHARE NAME: $SHARE_NAME" >> "$SCRIPT_LOG"
echo "INCLUDED DIRECTORIES: $INCLUDE_GLOB" >> "$SCRIPT_LOG"

cd "$BACKUP_BASE"
echo "PWD changed to $(pwd)" | tee -a "$SCRIPT_LOG"

DRY_RUN_COMMAND=(rsync --dry-run "${RSYNC_ARGS[@]}" "$SHARE_BASE/" "$BACKUP_BASE/")

echo "Dry run: ${DRY_RUN_COMMAND[*]}" | tee -a "$SCRIPT_LOG"

read -p "Continue with dry run? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || {
	echo "User cancelled before dry run" >> "$SCRIPT_LOG"
	exit 1
}

echo "${DRY_RUN_COMMAND[*]}" >> "$BACKUP_LOG"
"${DRY_RUN_COMMAND[@]}" 2>&1 | tee -a "$BACKUP_LOG"

RSYNC_COMMAND=(rsync "${RSYNC_ARGS[@]}" "$SHARE_BASE/" "$BACKUP_BASE/")
echo "Backup: ${RSYNC_COMMAND[*]}" | tee -a "$SCRIPT_LOG"

read -p "Continue with running rsync? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || {
	echo "User cancelled before full sync" >> "$SCRIPT_LOG"
	exit 1
}

echo "${RSYNC_COMMAND[*]}" >> "$BACKUP_LOG"
"${RSYNC_COMMAND[@]}" 2>&1 | tee -a "$BACKUP_LOG"

RSYNC_EXIT_CODE=$?

echo "rsync completed with exit code $RSYNC_EXIT_CODE" | tee -a "$SCRIPT_LOG"

exit 0