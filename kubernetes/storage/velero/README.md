# Velero

Backups of cluster resources and, for pods that opt in, their volumes. Everything goes to the `velero`
bucket on SeaweedFS (`http://seaweedfs-all-in-one.seaweedfs:8333`) using the AWS plugin.

The `nfs` StorageClass has no snapshots, so volumes are copied from the node agent (kopia). Back up a
volume by annotating its pod, for example `backup.velero.io/backup-volumes: config`. The schedule
`daily` backs up the cluster resources at 03:00 and keeps them for 30 days.

## Credentials

`templates/velero-credentials.yaml` is a SealedSecret named `velero-credentials` (namespace `velero`)
with key `cloud`, an AWS credentials file for the `velero` identity of SeaweedFS. That identity lives
in `kubernetes/storage/seaweedfs/templates/seaweedfs-s3-config.yaml`, so both secrets must be
regenerated together, see the SeaweedFS README.
