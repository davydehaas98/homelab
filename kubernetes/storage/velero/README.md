# Velero

Backs up cluster resources and volumes daily at 02:00 UTC (kept 30 days) to the `velero` bucket on SeaweedFS, whose data
is on `tank`. Each volume gets a CSI snapshot, which a data mover pod copies to the bucket with Kopia before the snapshot
is removed, so every file in a volume is from the same moment. A new volume is included without any setting.

Left out are the namespaces in `excludedNamespaces` in `values.yaml`, whose data is not worth keeping or is the bucket
itself, and claims with the label `velero.io/exclude-from-backup: "true"`: the media, the Immich library and the Plex
cache. A pod with the annotation `backup.velero.io/backup-volumes` would get a copy of its live files instead of a
snapshot, so don't set it.

The dumps and copies of [`storage/zfs-localpv`](../zfs-localpv/README.md) run next to this until restores from here are
proven.

`templates/velero-credentials.yaml` holds the `velero` identity of SeaweedFS and is sealed together with SeaweedFS's
config, see the [SeaweedFS README](../seaweedfs/README.md#credentials). That rotates the Loki credentials too: restart
SeaweedFS first, then Loki, after the three Secrets are applied.
