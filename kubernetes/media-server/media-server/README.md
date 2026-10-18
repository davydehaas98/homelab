# Media server

The `media` claim (`templates/storage.yaml`) is the NFS share `/mnt/storage` on the home server
(`yggdrasil`, `192.168.1.44`). Apps in the `media-server` namespace mount their media and download
paths from it.

## Config volumes

Every app keeps its configuration and SQLite database in `/config`. SQLite does not belong on NFS: killed
pods leave locks behind, and one restart ended in a `disk I/O error` for Radarr. So each app has an iSCSI
disk on yggdrasil. A node logs in to the disk and mounts it as a local ext4 disk, so file locking works,
and the pod can still move to any node.

- **One target per app.** The disk of an app is LUN 0 of its own target `iqn.2026-10.nl.davydehaas:<app>`.
  When a pod stops, the driver logs the node out of the whole target. Apps that shared one target cut each
  other's disk when a neighbour on the same node restarted.
- **Mounting.** The Talos images contain the `siderolabs/iscsi-tools` extension, but the kubelet of Talos
  cannot run `iscsiadm` for a plain `iscsi` volume. The democratic-csi driver `node-manual`
  (`kubernetes/storage/democratic-csi`) mounts the disks: it runs `iscsiadm` on the host and attaches the
  volumes the `app` library chart writes. It creates no disks, `lun.sh` does.
- **In the chart.** The `app` library chart (`kubernetes/_library/app`) renders a static PV and a claim
  `<app>-config` for `persistence.iscsi` (`targetPortal`, `iqn`, `lun`). A disk holds one ext4 filesystem,
  so it must only ever be mounted by one pod (`ReadWriteOnce`, `replicas: 1`).

| App      | Target (`iqn.2026-10.nl.davydehaas:...`) | Size | Volume now         |
|----------|------------------------------------------|------|--------------------|
| Prowlarr | `prowlarr`                               | 1G   | iSCSI              |
| SABnzbd  | `sabnzbd`                                | 1G   | iSCSI              |
| Sonarr   | `sonarr`                                 | 5G   | iSCSI              |
| Radarr   | `radarr`                                 | 5G   | iSCSI              |
| Lidarr   | `lidarr`                                 | 2G   | iSCSI              |
| Seerr    | `seerr`                                  | 1G   | iSCSI              |
| Jellyfin | `jellyfin`                               | 10G  | iSCSI              |
| Bazarr   | `bazarr`                                 | 1G   | iSCSI              |
| memos    | `memos`                                  | 1G   | NFS (not deployed) |

Keep this table up to date when an app moves.

## Making the disk of an app

`lun.sh` does the work on yggdrasil. Copy it there (`scp lun.sh davy@yggdrasil:`); `DRY_RUN=1` prints the
commands instead of running them:

```shell
sudo sh lun.sh create <app> <size>      # image file, ext4, own target with LUN 0, backup folder on the RAID
sudo sh lun.sh copy <app> [source-dir]  # old NFS config into the image
sudo sh lun.sh migrate <app>            # an image of the first setup (shared target) gets its own target
sudo sh lun.sh retire                   # remove the shared target `...:yggdrasil`, once every app has moved
sudo sh lun.sh status                   # targets, LUNs and sessions
```

### Moving an app from NFS

Move one app at a time. The app is down for a few minutes. The example is Radarr.

1. Make a backup in the app (System > Backup > Backup Now) and download it.

2. Stop the app, while it still runs from NFS. Argo CD scales it back up (the parent apps `argocd` and
   `applications` have self-heal too), so push a commit that only sets `replicas: 0` in the app's
   `values.yaml`, and wait until the pod is gone:

   ```shell
   kubectl -n media-server get pods
   ```

3. On yggdrasil, create the disk and copy the configuration of the old NFS volume
   (`nfs-subdir-external-provisioner` names it `media-server-<app>-config-pvc-<uid>`) into it. The
   `Backups` folder of the app does not go into the image: it is copied to
   `/mnt/md0/kubernetes/backups/<app>` (the RAID, `backups` claim), so the zips of the app survive a lost disk:

   ```shell
   sudo sh lun.sh create radarr 5G
   sudo sh lun.sh copy radarr
   sudo sh lun.sh status
   ```

4. Push the `iscsi` block, still with `replicas: 0`, and the backup folder of the app (the library mounts it
   at `/config/Backups`, after the volume of `/config`):

   ```yaml
   media:
     claimName: media
     mounts:
       - mountPath: /downloads
         subPath: downloads
       - mountPath: /movies
         subPath: media/movies

   backups:
     claimName: backups
     subPath: radarr

   persistence:
     size: 5Gi
     iscsi:
       targetPortal: 192.168.1.44:3260
       iqn: iqn.2026-10.nl.davydehaas:radarr
       lun: 0
   ```

   That sync fails on the claim, as a bound claim cannot change its volume. This is expected.

5. Delete the old claim and sync by hand (Argo CD does not retry a failed sync). It creates the static
   PV `media-server-<app>-config` and a new claim bound to it. The data of the old volume stays on
   yggdrasil. (If the PV `media-server-<app>-config` exists already from an earlier try, delete it too:
   `kubectl delete pv media-server-<app>-config`, as a PV cannot change its volume source.)

   ```shell
   kubectl -n media-server delete pvc radarr-config
   argocd app sync radarr
   ```

6. Push `replicas: 1`, and check that the pod mounted the disk and the app kept its configuration:

   ```shell
   kubectl -n media-server get pvc radarr-config
   kubectl -n media-server exec radarr-0 -- df -h /config
   kubectl -n media-server exec radarr-0 -- ls /config/Backups
   ```

   `df` has to show a `/dev/...` device (ext4), not `192.168.1.44:...`.

7. Remove the old NFS folder of the app on yggdrasil by hand once it has run fine for a while.

### Adding a new app

An app that never ran in the cluster has no NFS volume to migrate, so run `lun.sh create` before the app
is first synced, otherwise the pod hangs in `ContainerCreating` until the disk exists. The new disk is
owned by root: run `lun.sh copy <app> <folder>` too (with an empty folder if there is nothing to keep),
which sets the owner and clears `lost+found`. To keep the configuration of a Docker container on
yggdrasil, stop that container first (so the two instances do not manage the same library), pass its
config folder to `lun.sh copy`, and remove the container from the `home-server` repo too, or its next
deploy starts it again.

### When a disk shows an I/O error

A pod that stops on a node logs that node out of its own target only. Targets are per app, so neighbours
are safe. If a disk does show `I/O error` anyway (`kubectl exec <app>-0 -- ls /config`), look at the
kernel log (`talosctl -n <node> dmesg | grep -i iscsi`), then delete the pod: the driver stages the
volume again.

## Target setup (yggdrasil)

Run once on the server. This is not deployed by CI and does not touch the Docker stacks (Plex keeps
running). The targets themselves are made by `lun.sh`.

```shell
sudo apt install targetcli-fb rsync
sudo systemctl enable --now rtslib-fb-targetctl
```

Every target accepts any initiator without CHAP (`lun.sh` sets `authentication=0 generate_node_acls=1`),
so access is limited by the firewall instead. `targetcli` creates a portal on `0.0.0.0:3260` per target.
Only the cluster nodes may reach it. When `ufw` is active:

```shell
for ip in 192.168.1.50 192.168.1.51 192.168.1.52 192.168.1.53; do
  sudo ufw allow from ${ip} to any port 3260 proto tcp
done
```

Do not forward port 3260 on the router.

## Backups

The image files are plain files on the `/mnt/md0` RAID. Copy them while the app is stopped
(`replicas: 0`). The apps' own backups (Servarr: System > Backup) are zips on the same RAID in
`/mnt/md0/kubernetes/backups/<app>` (the `backups` claim), so they survive a lost disk. Velero (not deployed
yet) cannot snapshot a static disk.
