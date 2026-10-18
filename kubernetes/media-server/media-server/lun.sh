#!/bin/sh
# Creates the iSCSI LUN of a media-server app on yggdrasil, and copies the app's old NFS config into it.
# Run it on yggdrasil with sudo, see README.md for the whole procedure.
#
#   sudo sh lun.sh create <app> <lun> <size>   image file, ext4, exported as LUN <lun>, backup folder on NFS
#   sudo sh lun.sh copy <app> [source-dir]      config from the app's old NFS folder into the image
#   sudo sh lun.sh status                       LUNs and sessions of the target
#
# Example: sudo sh lun.sh create radarr 3 5G && sudo sh lun.sh copy radarr
# DRY_RUN=1 prints the commands instead of running them.
set -eu

IQN=iqn.2026-10.nl.davydehaas:yggdrasil
IMG_DIR=/mnt/md0/iscsi            # the image files, one per app
NFS_DIR=/mnt/md0/kubernetes       # where nfs-subdir-external-provisioner keeps the old volumes
BACKUP_DIR=/mnt/md0/kubernetes/backups   # the apps' own backups, on the RAID, mounted at /config/Backups
OWNER=1400:1400                   # owner of the media on the share, the user the apps run as

die() { echo "error: $*" >&2; exit 1; }

run() {
  if [ -n "${DRY_RUN:-}" ]; then echo "+ $*"; else "$@"; fi
}

usage() {
  sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'
  exit 1
}

check_app() {
  case "$1" in
    ''|*[!a-z0-9-]*|-*) die "app must be lowercase letters, digits and dashes, got '$1'" ;;
  esac
}

need_root() {
  [ -n "${DRY_RUN:-}" ] || [ "$(id -u)" = 0 ] || die "run with sudo"
}

cmd_create() {
  [ $# -eq 3 ] || usage
  app=$1; lun=$2; size=$3
  check_app "$app"
  case "$lun" in ''|*[!0-9]*) die "lun must be a number, got '$lun'" ;; esac
  case "$size" in [1-9]*[MG]) ;; *) die "size must look like 512M or 5G, got '$size'" ;; esac
  case "${size%[MG]}" in ''|*[!0-9]*) die "size must look like 512M or 5G, got '$size'" ;; esac
  need_root

  img="$IMG_DIR/$app-config.img"
  name="$app-config"

  if [ -z "${DRY_RUN:-}" ]; then
    command -v targetcli >/dev/null || die "targetcli is not installed, see 'Target setup' in README.md"
    targetcli ls /iscsi | grep -q "$IQN" || die "target $IQN does not exist, see 'Target setup' in README.md"
    [ ! -e "$img" ] || die "$img exists already, refusing to overwrite it"
    ! targetcli ls /backstores/fileio | grep -q "o- $name " || die "backstore $name exists already"
    ! targetcli ls "/iscsi/$IQN/tpg1/luns" | grep -q "o- lun$lun " || die "LUN $lun is in use, see 'status'"
  else
    echo "(dry run: checks skipped)"
  fi

  run mkdir -p "$IMG_DIR"
  run truncate -s "$size" "$img"
  run mkfs.ext4 -q -F -m 0 -L "$name" "$img"
  run targetcli /backstores/fileio create "name=$name" "file_or_dev=$img"
  run targetcli "/iscsi/$IQN/tpg1/luns" create "/backstores/fileio/$name" "lun=$lun"
  run targetcli saveconfig
  run install -d -o "${OWNER%:*}" -g "${OWNER#*:}" "$BACKUP_DIR/$app"
  echo "LUN $lun created for $app: $img ($size), backups in $BACKUP_DIR/$app"
  echo "Set persistence.iscsi.lun: $lun in kubernetes/media-server/$app/values.yaml"
}

cmd_copy() {
  [ $# -ge 1 ] && [ $# -le 2 ] || usage
  app=$1
  check_app "$app"
  need_root
  img="$IMG_DIR/$app-config.img"

  if [ -n "${2:-}" ]; then
    src=$2
  elif [ -n "${DRY_RUN:-}" ]; then
    src="$NFS_DIR/media-server-$app-config-pvc-<uid>"
  else
    set -- "$NFS_DIR"/media-server-"$app"-config-pvc-*
    [ -d "$1" ] || die "no old NFS volume for $app in $NFS_DIR, pass the folder as the second argument"
    [ $# -eq 1 ] || die "more than one old NFS volume for $app, pass the right folder as the second argument: $*"
    src=$1
  fi

  if [ -z "${DRY_RUN:-}" ]; then
    command -v rsync >/dev/null || die "rsync is not installed"
    [ -f "$img" ] || die "$img does not exist, run 'create' first"
    [ -d "$src" ] || die "$src is not a folder"
    grep -q " $img " /proc/mounts 2>/dev/null && die "$img is mounted already"
    echo "Sessions of the target (the app must be stopped, replicas: 0):"
    targetcli sessions || true
  else
    echo "(dry run: checks skipped)"
  fi

  mnt=$(mktemp -d "/mnt/lun-$app.XXXXXX")
  [ -z "${DRY_RUN:-}" ] || rmdir "$mnt"
  trap 'umount "$mnt" 2>/dev/null || true; rmdir "$mnt" 2>/dev/null || true' EXIT
  run mount -o loop "$img" "$mnt"
  # The app's own backups go to the RAID (mounted at /config/Backups), not into the LUN
  # --delete makes the image an exact copy, so a second run leaves no stale -wal or -shm files of a first one
  run rsync -aHAX --delete --exclude=/Backups "$src/" "$mnt/"
  run rm -rf "$mnt/lost+found"
  run chown "$OWNER" "$mnt"
  if [ -n "${DRY_RUN:-}" ] || [ -d "$src/Backups" ]; then
    run install -d -o "${OWNER%:*}" -g "${OWNER#*:}" "$BACKUP_DIR/$app"
    run rsync -a --chown="$OWNER" "$src/Backups/" "$BACKUP_DIR/$app/"
  fi
  run df -h "$mnt"
  run umount "$mnt"
  run rmdir "$mnt"
  trap - EXIT
  run e2fsck -fn "$img"
  echo "Copied $src into $img"
}

cmd_status() {
  need_root
  run targetcli ls "/iscsi/$IQN/tpg1/luns"
  run targetcli sessions
}

[ $# -ge 1 ] || usage
cmd=$1; shift
case "$cmd" in
  create) cmd_create "$@" ;;
  copy) cmd_copy "$@" ;;
  status) cmd_status ;;
  *) usage ;;
esac
