#!/bin/sh
# Creates the iSCSI disk of a media-server app on yggdrasil, and copies the app's old NFS config into it.
# Run it on yggdrasil with sudo, see README.md for the whole procedure.
#
# Every app gets its own iSCSI target (iqn.2026-10.nl.davydehaas:<app>) with the disk as LUN 0. The nodes
# log out of a whole target when one pod stops, so apps that share a target would cut each other's disk.
#
#   sudo sh lun.sh create <app> <size>         image file, ext4, own target with LUN 0, backup folder on the RAID
#   sudo sh lun.sh copy <app> [source-dir]      config from the app's old NFS folder into the image
#   sudo sh lun.sh migrate <app>                give an existing image its own target (from the shared one)
#   sudo sh lun.sh retire                       remove the old shared target, after every app has moved
#   sudo sh lun.sh status                       targets, LUNs and sessions
#
# Example: sudo sh lun.sh create radarr 5G && sudo sh lun.sh copy radarr
# DRY_RUN=1 prints the commands instead of running them. OWNER=<uid>:<gid> sets the owner of the disk (default 1400:1400).
set -eu

IQN_PREFIX=iqn.2026-10.nl.davydehaas
OLD_IQN=$IQN_PREFIX:yggdrasil     # the shared target of the first setup
IMG_DIR=/mnt/md0/iscsi            # the image files, one per app
NFS_DIR=/mnt/md0/kubernetes       # where nfs-subdir-external-provisioner keeps the old volumes
BACKUP_DIR=/mnt/md0/kubernetes/backups   # the apps' own backups, on the RAID, mounted at /config/Backups
# Owner of the media on the share, the user the apps run as. Disks of apps that run as another user set OWNER
OWNER=${OWNER:-1400:1400}

die() { echo "error: $*" >&2; exit 1; }

run() {
  if [ -n "${DRY_RUN:-}" ]; then echo "+ $*"; else "$@"; fi
}

usage() {
  sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'
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

need_targetcli() {
  [ -n "${DRY_RUN:-}" ] || command -v targetcli >/dev/null || die "targetcli is not installed (apt install targetcli-fb)"
}

target_exists() {
  targetcli ls /iscsi | grep -q "o- $1 "
}

# A target of its own for the backstore <app>-config, with the disk as LUN 0. Any initiator may log in
# without CHAP, access is limited by the firewall instead (see README.md)
add_target() {
  app=$1
  iqn="$IQN_PREFIX:$app"
  run targetcli /iscsi create "$iqn"
  run targetcli "/iscsi/$iqn/tpg1" set attribute authentication=0 generate_node_acls=1 cache_dynamic_acls=1 demo_mode_write_protect=0
  run targetcli "/iscsi/$iqn/tpg1/luns" create "/backstores/fileio/$app-config" lun=0
}

cmd_create() {
  [ $# -eq 2 ] || usage
  app=$1; size=$2
  check_app "$app"
  case "$size" in [1-9]*[MG]) ;; *) die "size must look like 512M or 5G, got '$size'" ;; esac
  case "${size%[MG]}" in ''|*[!0-9]*) die "size must look like 512M or 5G, got '$size'" ;; esac
  need_root
  need_targetcli

  img="$IMG_DIR/$app-config.img"
  name="$app-config"

  if [ -z "${DRY_RUN:-}" ]; then
    [ ! -e "$img" ] || die "$img exists already, refusing to overwrite it"
    ! targetcli ls /backstores/fileio | grep -q "o- $name " || die "backstore $name exists already"
    ! target_exists "$IQN_PREFIX:$app" || die "target $IQN_PREFIX:$app exists already"
  else
    echo "(dry run: checks skipped)"
  fi

  run mkdir -p "$IMG_DIR"
  run truncate -s "$size" "$img"
  run mkfs.ext4 -q -F -m 0 -L "$name" "$img"
  run targetcli /backstores/fileio create "name=$name" "file_or_dev=$img"
  add_target "$app"
  run targetcli saveconfig
  run install -d -o "${OWNER%:*}" -g "${OWNER#*:}" "$BACKUP_DIR/$app"
  echo "Disk created for $app: $img ($size), target $IQN_PREFIX:$app LUN 0, backups in $BACKUP_DIR/$app"
  echo "Set persistence.iscsi.iqn: $IQN_PREFIX:$app and lun: 0 in kubernetes/media-server/$app/values.yaml"
}

cmd_migrate() {
  [ $# -eq 1 ] || usage
  app=$1
  check_app "$app"
  need_root
  need_targetcli

  if [ -z "${DRY_RUN:-}" ]; then
    targetcli ls /backstores/fileio | grep -q "o- $app-config " || die "backstore $app-config does not exist, use 'create'"
    ! target_exists "$IQN_PREFIX:$app" || die "target $IQN_PREFIX:$app exists already"
    echo "Sessions of the targets (the app must be stopped, replicas: 0):"
    targetcli sessions || true
  else
    echo "(dry run: checks skipped)"
  fi

  add_target "$app"
  run targetcli saveconfig
  echo "Target $IQN_PREFIX:$app with the disk of $app as LUN 0"
  echo "Set persistence.iscsi.iqn: $IQN_PREFIX:$app and lun: 0 in kubernetes/media-server/$app/values.yaml"
}

cmd_retire() {
  need_root
  need_targetcli
  if [ -z "${DRY_RUN:-}" ]; then
    target_exists "$OLD_IQN" || die "target $OLD_IQN does not exist"
    echo "Sessions of the targets (none may use $OLD_IQN):"
    targetcli sessions || true
  fi
  run targetcli /iscsi delete "$OLD_IQN"
  run targetcli saveconfig
  echo "Removed $OLD_IQN, the images and the per-app targets stay"
  echo "The nodes keep their session to a removed target and stack dead mounts on it. On every democratic-csi node pod run:"
  echo "  kubectl exec -n democratic-csi <pod> -c csi-driver -- chroot /host iscsiadm -m node -T $OLD_IQN -p 192.168.1.44:3260 --logout"
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
    echo "Sessions of the targets (the app must be stopped, replicas: 0):"
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
  run targetcli ls /iscsi
  run targetcli sessions
}

[ $# -ge 1 ] || usage
cmd=$1; shift
case "$cmd" in
  create) cmd_create "$@" ;;
  copy) cmd_copy "$@" ;;
  migrate) cmd_migrate "$@" ;;
  retire) cmd_retire ;;
  status) cmd_status ;;
  *) usage ;;
esac
