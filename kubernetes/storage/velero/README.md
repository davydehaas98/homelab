# Velero

Not deployed. Backs up cluster resources daily at 03:00 (kept 30 days) to the `velero` bucket on SeaweedFS. The
`nfs` StorageClass has no snapshots, so the node agent copies the volumes of pods annotated with
`backup.velero.io/backup-volumes`.

`templates/velero-credentials.yaml` holds the `velero` identity of SeaweedFS and is sealed together with SeaweedFS's
config, see the [SeaweedFS README](../seaweedfs/README.md#credentials).
