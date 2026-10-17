# Media server

The `media` claim (`templates/storage.yaml`) is the NFS share `/mnt/storage` on the home server
(`yggdrasil`, `192.168.1.44`). Apps in the `media-server` namespace mount their media and download
paths from it.

## iSCSI config volumes

SQLite databases corrupt on NFS, so the configuration of Sonarr, Radarr and Prowlarr (and the data of memos) lives on iSCSI LUNs on
yggdrasil instead. A node logs in to the target and mounts the LUN as a local ext4 disk, so file
locking works, and the pod can still move to any node. The Talos images already contain the
`siderolabs/iscsi-tools` extension.

| App      | LUN | Image file                             | Size |
|----------|-----|----------------------------------------|------|
| Sonarr   | 0   | `/mnt/md0/iscsi/sonarr-config.img`     | 5G   |
| Prowlarr | 1   | `/mnt/md0/iscsi/prowlarr-config.img`   | 1G   |
| Radarr   | 2   | `/mnt/md0/iscsi/radarr-config.img`     | 5G   |
| memos    | 3   | `/mnt/md0/iscsi/memos-config.img`      | 1G   |

The apps are built from the `app` library chart (`kubernetes/_library/app`), which
renders a static PV + PVC for the LUN in `persistence.iscsi` of the app's `values.yaml`. A LUN holds
one ext4 filesystem, so it must only ever be mounted by one pod (`ReadWriteOnce`, `replicas: 1`).

### Migrating from the `nfs` StorageClass

The volume of a StatefulSet cannot be changed in place, and Argo CD self-heals a manual scale-down,
so this takes two pushes. Do one app at a time, Prowlarr first since it is the smallest.

1. Stop the app while it still runs from NFS: push a commit that only sets `replicas: 0` (in
   `values.yaml`, or in `templates/statefulset.yaml` if the app still has `replicas: 1` hardcoded),
   and wait until Argo CD has synced and the pod is gone. Do not push the iSCSI volume yet: its
   StatefulSet change fails to sync, which would leave the old pod running.

   ```shell
   kubectl -n media-server get pods
   ```

2. On yggdrasil, create the image file with the configuration copied from the old NFS volume
   (`nfs-subdir-external-provisioner` names it `<namespace>-<pvc>-<pv>`, and keeps it on delete):

   ```shell
   APP=prowlarr   # or sonarr
   SIZE=1G        # 5G for sonarr
   SRC=$(ls -d /mnt/md0/kubernetes/media-server-config-${APP}-0-pvc-*)
   echo "${SRC}"

   sudo mkdir -p /mnt/md0/iscsi
   sudo truncate -s ${SIZE} /mnt/md0/iscsi/${APP}-config.img
   sudo mkfs.ext4 -F /mnt/md0/iscsi/${APP}-config.img
   sudo mkdir -p /mnt/iscsi-${APP}
   sudo mount -o loop /mnt/md0/iscsi/${APP}-config.img /mnt/iscsi-${APP}
   sudo rsync -aHAX "${SRC}/" /mnt/iscsi-${APP}/
   sudo rm -rf /mnt/iscsi-${APP}/lost+found
   sudo umount /mnt/iscsi-${APP}
   ```

3. Export it as a LUN (the first time also installs and creates the target, see
   [Target setup](#target-setup-yggdrasil)):

   ```shell
   sudo targetcli /backstores/fileio create name=${APP}-config file_or_dev=/mnt/md0/iscsi/${APP}-config.img
   sudo targetcli /iscsi/iqn.2026-10.nl.davydehaas:yggdrasil/tpg1/luns create /backstores/fileio/${APP}-config
   sudo targetcli saveconfig
   sudo targetcli ls /iscsi
   ```

   Check that the LUN number `targetcli` printed matches `persistence.iscsi.lun` in the app's
   `values.yaml`.

4. Switch the app over: set `replicas: 1` again (together with the `config-volume.yaml` and
   StatefulSet changes, if they are not on `main` yet) and push. That sync fails, as
   `volumeClaimTemplates` is immutable, so delete the old StatefulSet and its claim:

   ```shell
   kubectl -n media-server delete statefulset ${APP}
   kubectl -n media-server delete pvc config-${APP}-0
   ```

   Automated sync does not retry a failed commit, so sync the app by hand from the Argo CD UI
   (or `argocd app sync ${APP}`). It recreates the StatefulSet with the iSCSI volume.

   Deleting the old PVC does not delete the data: the `nfs` StorageClass retains and archives it on
   yggdrasil. Remove that directory by hand once the app runs fine from the LUN.

5. Verify the pod mounted the LUN and the app kept its configuration:

   ```shell
   kubectl -n media-server get pvc
   kubectl -n media-server exec ${APP}-0 -- df -h /config
   ```

### Adding a new app (Radarr)

An app that never ran in the cluster has no NFS volume to migrate, so create its LUN before the app
is first synced, otherwise the pod hangs in `ContainerCreating` until the LUN exists. To keep the
configuration of the Docker container on yggdrasil, copy it into the image (step 2 above, with
`SRC=/home/homelab/home-server/radarr/config`) and stop that container first, so the two instances
do not manage the same library:

```shell
docker stop radarr
```

Remove it from the `home-server` repo too, or its next deploy starts it again. Then export the LUN
(step 3 above) and push the app.

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
(`replicas: 0`). Velero (not deployed yet) would also pick the `/config` volumes up, as the PVCs
carry `backup.velero.io/include: "true"`.
