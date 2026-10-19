---
name: add-iscsi-disk
description: Use when an app has SQLite or a database and needs its own iSCSI disk on yggdrasil, or when moving an app's config from NFS or a Docker container to one. Gives the values and the commands to run on yggdrasil.
---

# Add an iSCSI disk

SQLite and databases break on NFS. Read `kubernetes/media-server/media-server/README.md` ("iSCSI disks") first; it is
the source of truth, with the script at `kubernetes/media-server/media-server/lun.sh`.

The disk is made on yggdrasil. You cannot do that from here, so **give the user the commands to run there** and wait.

1. **One target per app**: `iqn.2026-10.nl.davydehaas:<app>`, LUN 0. Never share a target; a node logs out of the
   whole target when one pod stops.
2. **Values** in the app's `values.yaml`:

   ```yaml
   persistence:
     size: <size>
     iscsi:
       targetPortal: 192.168.1.44:3260
       iqn: iqn.2026-10.nl.davydehaas:<app>
       lun: 0
   ```

   One pod only: `replicas: 1`, the default `StatefulSet`. Velero cannot snapshot these disks, see "Backups" in the
   README.
3. **Owner.** The default is `1400:1400`. For an app that runs as another user set `OWNER=<uid>:<gid>` and match
   `fsGroup`/`runAsUser` in the pod. Check the image's user, do not guess.
4. **Commands for the user**, on yggdrasil, from the folder with `lun.sh`:

   ```shell
   sudo sh lun.sh create <app> <size>
   sudo OWNER=<uid>:<gid> sh lun.sh copy <app> <folder>
   ```

   `DRY_RUN=1` prints the commands first. `copy` takes a folder, which may be empty.
5. **If the source is a Docker container's config**, stop the container first, and remove it from `home-server`, or its
   next deploy starts it again.
6. **Order matters.** The disk must exist before the app's first sync, or the pod waits in `ContainerCreating`.
7. **Add the app to the table** in the README with its target and size.
8. **I/O errors** afterwards: `talosctl -n <node> dmesg | grep -i iscsi`, then delete the pod. Always run CLIs in
   the dev container.
