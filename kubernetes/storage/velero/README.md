# Velero

Backs up cluster resources daily at 02:00 UTC (kept 30 days) to the `velero` bucket on SeaweedFS, whose data is on
`tank`. The node agent copies the volumes of pods annotated with `backup.velero.io/backup-volumes`; an app sets
`persistence.backup: true` for that. The databases are covered by the backup of
[`storage/zfs-localpv`](../zfs-localpv/README.md), not here.

`templates/velero-credentials.yaml` holds the `velero` identity of SeaweedFS and is sealed together with SeaweedFS's
config, see the [SeaweedFS README](../seaweedfs/README.md#credentials). That rotates the Loki credentials too: restart
SeaweedFS first, then Loki, after the three Secrets are applied.
