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

Its VolumeSnapshotClass needs the CRDs of `storage/snapshot-controller`; on a fresh cluster sync this app again once
that one is healthy.

Talos imports the pools at boot; their mountpoints must be under `/var`.
