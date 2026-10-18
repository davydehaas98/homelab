# Media server

The `media` claim is the NFS share `/mnt/storage` on the home server (`yggdrasil`, `192.168.1.44`), and the
`backups` claim is `/mnt/md0/kubernetes/backups` on its RAID. Both are in the `media-server` namespace.

## iSCSI disks

SQLite and databases break on NFS, so each such app has an ext4 disk on yggdrasil, served over iSCSI:

- **One target per app**, `iqn.2026-10.nl.davydehaas:<app>` with the disk as LUN 0. A node logs out of the whole
  target when a pod stops, so a shared target cuts its neighbours' disks.
- **One pod per disk** (`ReadWriteOnce`, `replicas: 1`).
- **Mounted by democratic-csi** (`kubernetes/storage/democratic-csi`), as the Talos kubelet cannot run `iscsiadm`.
  The library chart writes the PV and claim for `persistence.iscsi`. Prometheus and Authentik write theirs in
  their own charts.
- **Made by `lun.sh`** on yggdrasil (`sudo sh lun.sh` lists the commands).

| App                | Target                 | Size |
|--------------------|------------------------|------|
| Prowlarr           | `prowlarr`             | 1G   |
| SABnzbd            | `sabnzbd`              | 1G   |
| Sonarr             | `sonarr`               | 5G   |
| Radarr             | `radarr`               | 5G   |
| Lidarr             | `lidarr`               | 2G   |
| Seerr              | `seerr`                | 1G   |
| Jellyfin           | `jellyfin`             | 10G  |
| Bazarr             | `bazarr`               | 1G   |
| Prometheus TSDB    | `prometheus`           | 10G  |
| Authentik Postgres | `authentik-postgresql` | 2G   |

### Adding an app

Create the disk before the app's first sync, or its pod waits in `ContainerCreating`. `copy` sets the owner
(`OWNER=<uid>:<gid>` when the app does not run as 1400) and fills the disk from a folder, which may be empty:

```shell
sudo sh lun.sh create <app> <size>
sudo OWNER=<uid>:<gid> sh lun.sh copy <app> <folder>
```

When the folder is a Docker container's config on yggdrasil, stop that container first and remove it from
`home-server`, or its next deploy starts it again.

### I/O errors

Check `talosctl -n <node> dmesg | grep -i iscsi`, then delete the pod so the driver stages the volume again.

## Server setup

Once on yggdrasil:

```shell
sudo apt install targetcli-fb rsync
sudo systemctl enable --now rtslib-fb-targetctl
for ip in 192.168.1.50 192.168.1.51 192.168.1.52 192.168.1.53; do
  sudo ufw allow from ${ip} to any port 3260 proto tcp
done
```

The targets have no CHAP, so only the nodes may reach port 3260. Never forward it on the router.

## Backups

The disk images are files in `/mnt/md0/iscsi`; copy one only while its app is stopped. The apps' own backups go
to the `backups` claim. Velero cannot snapshot these disks.
