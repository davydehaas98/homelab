# Home server to Talos

Plan to turn the home server (`yggdrasil`, `192.168.1.44`, Ubuntu) into a Talos worker of the cluster, with ZFS for
its storage and the Intel GPU for Plex. The Docker stack goes away with Ubuntu; only Plex moves into the cluster.

## Target layout

| Disk | Now | After |
|---|---|---|
| `sda`, 128G SATA SSD | Old Ubuntu LVM, unmounted | Talos system disk |
| `nvme0n1`, 500G NVMe | Ubuntu root | Partitions 1–2 kept, as their GRUB boots Talos from `sda`; pool `fast` on partition 3: databases, app configs, Plex, Prometheus |
| `sdb`, `sdd`, `sde`, 3x 4T | md0 RAID5, ext4, 115G used | Pool `tank`, RAIDZ1: shared files, SeaweedFS, photos, backups |
| `sdc`, 16T | ext4, media (13.1T, 96%) | Unchanged ext4, mounted by Talos; no redundancy until a second 16T is mirrored |

Apps with state run on the node, on volumes of a local ZFS CSI driver. Apps on the RK1 nodes reach them through their
Services; files they need come from an NFS server pod on the node. Block storage over the network (iSCSI) ends. The
node keeps `192.168.1.44` through its DHCP reservation.

## 1. Prepare (Ubuntu, nothing destructive)

- The rest of the Docker stack (Traefik, its Authentik, open-webui, wg-easy) runs until the cutover and is dropped
  with its data. Plex stays in Docker for its hardware transcoding and moves once, in the cutover.
- Find what fills the 257G of `/` and keep what is needed: `sudo du -xsh /var/lib/docker /home /opt /srv /root`.
- Confirm `sda` holds nothing needed; it is wiped by the Talos install.
- Long SMART test on the three 4T disks, all `Completed without error`.
- Give the media partition a GPT label, which Talos selects it by:

  ```shell
  sudo sgdisk -c 1:media /dev/sdc
  ```

- An off-site copy of md0 (115G) and of the Plex config (74G).

## 2. md0 to `tank` (Ubuntu)

The cluster keeps using NFS and iSCSI from Ubuntu. Mounting `tank` at `/mnt/md0` keeps every path in the repo,
`/etc/exports` and the iSCSI backstores as they are. Every app on iSCSI or NFS is down meanwhile, Authentik included.

1. Stop the apps on iSCSI and NFS (scale to 0), then `sudo systemctl stop nfs-server rtslib-fb-targetctl`.
2. Copy md0 to `sdc`: `sudo rsync -aHAX /mnt/md0/ /mnt/storage/md0-migration/`.
3. Remove md0: `umount /mnt/md0`, `mdadm --stop /dev/md0`, `mdadm --zero-superblock` and `wipefs -a` on the three
   disks, and drop md0 from `/etc/fstab` and `/etc/mdadm/mdadm.conf`.
4. Create the pool, with the disks by ID:

   ```shell
   sudo zpool create -o ashift=12 -O compression=lz4 -O atime=off -O xattr=sa -O acltype=posixacl \
     -O mountpoint=/mnt/md0 tank raidz1 /dev/disk/by-id/<sdb> /dev/disk/by-id/<sdd> /dev/disk/by-id/<sde>
   ```

5. One dataset per top-level folder (`kubernetes`, `iscsi`, `media-server`, `home-server`), copy the data back,
   start the services and the apps.
6. Never run `zpool upgrade` on Ubuntu: the pool must stay importable by the Talos ZFS extension (OpenZFS 2.4.4 on
   Talos 1.14).

## 3. Talos for the node (repo)

Prepared while Ubuntu still runs; nothing in it acts before the node joins.

- Done, and idle until the node joins:
  - `talos/i5-10600k/` with the node `midgard-0` (`talos/README.md`), tainted
    `davydehaas.dev/dedicated=storage:NoSchedule`. tuppr keeps its schematic, as it swaps only the version of each
    node's install image.
  - `storage/zfs-localpv` (StorageClasses `zfs-fast` and `zfs-tank`) and `storage/snapshot-controller`. democratic-csi's
    local ZFS drivers do not run on Talos (democratic-csi#444).
  - `core/intel-gpu-resource-driver` (DRA) in place of `intel-device-plugins-gpu`. Check after the join that it lists
    the UHD 630 (`kubectl get resourceslices`); it is built for discrete GPUs first.
  - The taint tolerated by node-feature-discovery and the Velero node agent (node-exporter and fluent-bit tolerate
    every taint), the Kyverno exemptions, and Cilium announcing on `eno1` too.
- Requests and limits for the ZFS LocalPV and GPU driver pods, from their VPA once they run.
- On branch `worktree-talos-storage`, merged in the cutover: every app with data on midgard-0, none left on NFS (no
  NFS server pod). Each volume is a static ZFS volume (`storage/zfs-localpv`, its `volumes` list) that its claim binds
  to, filled before the merge by `fill-volumes.sh` from the app's iSCSI image or NFS folder on `tank`; the databases
  move as files too. The media is a `local` volume on `/var/mnt/media`. `zfs-fast` becomes the default StorageClass,
  and the library chart tolerates the taint for apps with a volume.
- On the same branch, Plex as a library app (`media-server/plex`, namespace `plex`): the same image and user, the
  media at the Docker paths, a GPU claim, and the host network of midgard-0, so the port forward, the Envoy route and
  Tautulli keep `192.168.1.44:32400`.

## 4. Cutover (one maintenance window)

All remote, over SSH. From the shutdown of Ubuntu, no NFS or iSCSI is served, so every app using them is down until
it has moved. Until step 6 the NVMe still holds Ubuntu: booting it again (a reboot, until Talos is the GRUB default)
and resetting the mountpoint of `tank` to `/mnt/md0` undoes the cutover. If Talos does not come up on the network,
only a power cycle at home returns to Ubuntu.

1. `pg_dump` every Postgres (the CloudNativePG clusters of AirTrail, Immich and Nextcloud, Authentik, Tracearr) to
   `tank`, in case a database copied as files does not start.
2. Archive what the NVMe and `sda` hold besides Plex to `tank`, as both are wiped: `/home/homelab/home-server`
   (59G without Plex), the stale `/opt/appdata` (80G, from 2024) and `sda`'s old Ubuntu 20.04 (69G, last used
   April 2026).
3. Copy the Plex config to `tank` while Plex runs, then stop Plex and copy again, which only copies the changes:

   ```shell
   sudo rsync -aHAX --delete /home/homelab/home-server/plex/config/ /mnt/md0/plex-config/
   ```

4. Scale every app on iSCSI and NFS to 0. Then `sudo zfs set mountpoint=/var/mnt/tank tank` and
   `sudo zpool export tank`.
5. Write the Talos image to `sda`, boot it once from GRUB and apply the node config (`talos/README.md`). Check
   `talosctl get extensions` and that `tank` and `media` are mounted, then make Talos the GRUB default.
6. Create `fast` on the NVMe's third partition from a debug pod (`kubectl debug --profile sysadmin node/<node>`,
   `chroot /host zpool create -f ... -O mountpoint=/var/mnt/fast fast /dev/disk/by-id/<nvme>-part3`), keeping
   partitions 1–2 for GRUB, and the `k8s` datasets in both pools.
7. Check that the ZFS LocalPV and GPU driver pods run on the node, run `fill-volumes.sh`, then merge the branch. Argo
   CD cannot change the claims and StatefulSet claim templates whose storage moved: delete those, and the old PVs, so
   it makes them again on the ZFS volumes.
8. After Authentik restarts the OIDC policies stay invalid until the envoy-gateway controller restarts. Check every
   app; a database that does not start is restored from its dump.
9. Check Plex (filled from `plex-config` on `tank` like the others): the same server in the Plex app, and hardware
   transcoding (`kubectl get resourceslices` lists the UHD 630).

## 5. Clean up

Remove `fill-volumes.sh` and the `source` keys, democratic-csi, nfs-subdir-external-provisioner, `lun.sh`,
`persistence.iscsi` in the library chart, the iSCSI table, the `add-iscsi-disk` skill, the `home-server` Backend in
envoy-gateway, and `iscsi-tools` from the RK1 schematic. Update the storage section and the arm64 rule in `AGENTS.md`, and remove this file once done. Back up
`fast` to `tank` (Velero to SeaweedFS), as it is a single disk.

## Later

A second 16T disk: a pool on it, the media copied over, then `sdc` wiped and attached as its mirror (`zpool attach`).

## Open

- The undeployed apps with a volume (open-webui, sonarqube, wireguard) get a volume and the toleration when they are
  switched on.
