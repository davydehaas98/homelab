# NFS subdir external provisioner

Default StorageClass `nfs`. Volumes are subdirectories of the NFS export on the home server
(`yggdrasil`, `192.168.1.44`), which lives on the `/mnt/md0` RAID.

## NFS server (Ubuntu host, `yggdrasil`)

Run once on the server. This is not deployed by CI.

```shell
sudo apt install nfs-kernel-server
sudo mkdir -p /mnt/md0/kubernetes
echo '/mnt/md0/kubernetes 192.168.1.50(rw,sync,no_subtree_check,no_root_squash) 192.168.1.51(rw,sync,no_subtree_check,no_root_squash) 192.168.1.52(rw,sync,no_subtree_check,no_root_squash) 192.168.1.53(rw,sync,no_subtree_check,no_root_squash)' | sudo tee -a /etc/exports
sudo exportfs -ra
sudo systemctl enable --now nfs-server
sudo exportfs -v
```

Only the four nodes may mount it. `no_root_squash` is required so the provisioner can create
directories with the right owners. Do not forward port 2049 on the router.

PostgreSQL on NFS is discouraged. Move databases to local storage if they misbehave.
