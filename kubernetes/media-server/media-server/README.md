# Media server

The `media` claim (`templates/storage.yaml`) is the NFS share `/mnt/storage` on the home server
(`yggdrasil`, `192.168.1.44`). Apps in the `media-server` namespace mount their media and download
paths from it.

## Config volumes

Every app keeps its configuration and SQLite database in `/config`. For now that volume comes from the
default StorageClass (NFS). SQLite does not belong on NFS: killed pods leave locks behind, and one
restart ended in a `disk I/O error` for Radarr. The fix is an iSCSI LUN per app on yggdrasil. A node
logs in to the target and mounts the LUN as a local ext4 disk, so file locking works, and the pod can
still move to any node. The Talos images contain the `siderolabs/iscsi-tools` extension. The kubelet of Talos
cannot run `iscsiadm` for a plain `iscsi` volume, so the LUNs are mounted by the democratic-csi driver
`node-manual` (`kubernetes/storage/democratic-csi`), which runs `iscsiadm` on the host. It only attaches the
volumes the `app` library chart writes, it creates no LUNs.

The target `iqn.2026-10.nl.davydehaas:yggdrasil` exists (see [Target setup](#target-setup-yggdrasil)),
the LUNs do not yet. The number of a LUN is chosen when it is created and has to equal
`persistence.iscsi.lun` in the app's `values.yaml`:

| App      | LUN | Size | Volume now |
|----------|-----|------|------------|
| Prowlarr | 0   | 1G   | iSCSI      |
| SABnzbd  | 1   | 1G   | NFS        |
| Sonarr   | 2   | 5G   | NFS        |
| Radarr   | 3   | 5G   | NFS        |
| Lidarr   | 4   | 2G   | NFS        |
| Bazarr   | 5   | 1G   | NFS        |
| memos    | 100 | 1G   | NFS (not deployed) |

The apps of this namespace use 0 to 9, in the order of the media pipeline: indexers, downloads, the
managers (TV, movies, music), subtitles. The next media apps (Seerr, Tautulli, ...) take 6 and up. Apps
that are not part of the media stack start at 100; a new one gets the next free number in its range. The
target accepts LUN numbers up to 255.

Update the last column when an app has moved. The `app` library chart (`kubernetes/_library/app`)
renders a static PV and a claim `<app>-config` for the LUN in `persistence.iscsi`. A LUN holds one
ext4 filesystem, so it must only ever be mounted by one pod (`ReadWriteOnce`, `replicas: 1`).

## Moving an app to iSCSI

`lun.sh` does the work on yggdrasil. Copy it there once (`scp lun.sh davy@yggdrasil:`); it prints the
commands instead of running them with `DRY_RUN=1`:

```shell
sudo sh lun.sh create <app> <lun> <size>   # image file, ext4, exported as LUN <lun>, backup folder on NFS
sudo sh lun.sh copy <app> [source-dir]     # old NFS config into the image
sudo sh lun.sh status                      # LUNs and sessions
```

Move one app at a time, Radarr first (the biggest database). The app is down for a few minutes. The
example is Radarr, LUN 3.

1. Make a backup in the app (System > Backup > Backup Now) and download it.

2. Stop the app, while it still runs from NFS: push a commit that only sets `replicas: 0` in the app's
   `values.yaml`, and wait until Argo CD has synced and the pod is gone:

   ```shell
   kubectl -n media-server get pods
   ```

3. On yggdrasil, create the LUN and copy the configuration of the old NFS volume
   (`nfs-subdir-external-provisioner` names it `media-server-<app>-config-pvc-<uid>`) into it. The
   `Backups` folder of the app does not go into the image: it is copied to
   `/mnt/md0/kubernetes/backups/<app>` (the RAID, `backups` claim), so the zips of the app survive a lost LUN:

   ```shell
   sudo sh lun.sh create radarr 3 5G
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
       iqn: iqn.2026-10.nl.davydehaas:yggdrasil
       lun: 3
   ```

   That sync fails on the claim, as a bound claim cannot change its volume. This is expected.

5. Delete the old claim and sync by hand (Argo CD does not retry a failed sync). It creates the static
   PV `media-server-<app>-config` and a new claim bound to it. The data of the old volume stays on
   yggdrasil. (If the PV `media-server-<app>-config` exists already from an earlier try with another volume
   type, delete it too: `kubectl delete pv media-server-<app>-config`.)

   ```shell
   kubectl -n media-server delete pvc radarr-config
   argocd app sync radarr
   ```

6. Push `replicas: 1`, and check that the pod mounted the LUN and the app kept its configuration:

   ```shell
   kubectl -n media-server get pvc radarr-config
   kubectl -n media-server exec radarr-0 -- df -h /config
   kubectl -n media-server exec radarr-0 -- ls /config/Backups
   ```

   `df` has to show a `/dev/...` device (ext4), not `192.168.1.44:...`.

7. Remove the old NFS folder of the app on yggdrasil by hand once it has run fine for a while.

### Adding a new app

An app that never ran in the cluster has no NFS volume to migrate, so run `lun.sh create` before the app
is first synced, otherwise the pod hangs in `ContainerCreating` until the LUN exists. To keep the
configuration of a Docker container on yggdrasil, stop that container first (so the two instances do
not manage the same library), pass its config folder to `lun.sh copy <app> <folder>`, and remove the
container from the `home-server` repo too, or its next deploy starts it again.

### Target setup (yggdrasil)

Run once on the server. This is not deployed by CI and does not touch the Docker stacks (Plex keeps
running).

```shell
sudo apt install targetcli-fb
sudo targetcli /iscsi create iqn.2026-10.nl.davydehaas:yggdrasil
# Allow any initiator without CHAP, access is limited by the firewall below instead
sudo targetcli /iscsi/iqn.2026-10.nl.davydehaas:yggdrasil/tpg1 set attribute \
    authentication=0 generate_node_acls=1 cache_dynamic_acls=1 demo_mode_write_protect=0
sudo targetcli saveconfig
sudo systemctl enable --now rtslib-fb-targetctl
```

`targetcli` creates a portal on `0.0.0.0:3260`. Only the cluster nodes may reach it. When `ufw` is
active:

```shell
for ip in 192.168.1.50 192.168.1.51 192.168.1.52 192.168.1.53; do
  sudo ufw allow from ${ip} to any port 3260 proto tcp
done
```

Do not forward port 3260 on the router.

### Backups

The image files are plain files on the `/mnt/md0` RAID. Copy them while the app is stopped
(`replicas: 0`). The apps' own backups (Servarr: System > Backup) are zips on the same RAID in
`/mnt/md0/kubernetes/backups/<app>` (the `backups` claim), so they survive a lost LUN. Velero (not deployed yet) cannot snapshot a
static LUN.
