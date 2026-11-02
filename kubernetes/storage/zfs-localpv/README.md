# ZFS LocalPV

Volumes on the ZFS pools of `midgard-0`: StorageClass `zfs-fast` on the NVMe pool `fast`, `zfs-tank` on the RAIDZ1
pool `tank`. A volume is a dataset under `<pool>/k8s` and is bound to the node, so its pod tolerates the node's taint
`davydehaas.dev/dedicated=storage:NoSchedule`.

The pools and their `k8s` datasets are made by hand, from a privileged debug pod on the node:

```shell
kubectl debug -it --profile sysadmin --image=alpine node/midgard-0
chroot /host zfs create fast/k8s
chroot /host zfs create tank/k8s
```

## Static volumes

`volumes` in `values.yaml` lists each existing dataset, which `templates/volumes.yaml` imports with a ZFSVolume and a PV
`zfs-<name>`, and the app's claim names that PV and the pool's StorageClass. Create a new dataset by hand first, with
`quota` and `mountpoint=legacy`; a new app can just use a StorageClass instead. Removing an entry leaves the dataset;
destroy it by hand. To grow a volume, raise `size` and the app's claim in one change, then check the dataset's `quota`
followed.

The driver only mounts a ZFSVolume with `status.state: Ready`, and without it a pod that restarts waits in
`ContainerCreating` with `verifyMount: volume is not ready to be mounted`. Argo CD drops that field at the first sync after
it created the object, so after adding an entry, give the field a second owner with a server-side apply of the name and
`status.state: Ready`, using `--field-manager=manual-status`. A `kubectl patch` changes nothing while the field is still
`Ready`, so it does not keep it.

Its VolumeSnapshotClass needs the CRDs of `storage/snapshot-controller`; on a fresh cluster sync this app again once
that one is healthy.

Talos imports the pools at boot; their mountpoints must be under `/var`.

The volumes are backed up by [Velero](../velero/README.md).
