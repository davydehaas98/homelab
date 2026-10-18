# NFS subdir external provisioner

Default StorageClass `nfs`: volumes are folders in the export `/mnt/md0/kubernetes` on the home server's RAID
(`yggdrasil`, `192.168.1.44`). Not for SQLite or databases, which get an iSCSI disk, see
[the media-server README](../../media-server/media-server/README.md#iscsi-disks).

Once on yggdrasil:

```shell
sudo apt install nfs-kernel-server
sudo mkdir -p /mnt/md0/kubernetes
echo '/mnt/md0/kubernetes 192.168.1.50(rw,sync,no_subtree_check,no_root_squash) 192.168.1.51(rw,sync,no_subtree_check,no_root_squash) 192.168.1.52(rw,sync,no_subtree_check,no_root_squash) 192.168.1.53(rw,sync,no_subtree_check,no_root_squash)' | sudo tee -a /etc/exports
sudo exportfs -ra
sudo systemctl enable --now nfs-server
```

Only the nodes may mount it, and `no_root_squash` lets the provisioner set owners. Never forward port 2049 on the
router.
