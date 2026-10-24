# Velero

Backs up cluster resources daily at 03:00 (kept 30 days) to the `velero` bucket on SeaweedFS, whose data is on the
RAID of the home server. The `nfs` StorageClass has no snapshots, so the node agent copies the volumes of pods annotated
with `backup.velero.io/backup-volumes`; an app sets `persistence.backup: true` for that. The databases of CloudNativePG
are not covered.

`templates/velero-credentials.yaml` holds the `velero` identity of SeaweedFS and is sealed together with SeaweedFS's
config, see the [SeaweedFS README](../seaweedfs/README.md#credentials). That rotates the Loki credentials too: restart
SeaweedFS first, then Loki, after the three Secrets are applied.
