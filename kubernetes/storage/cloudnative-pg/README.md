# CloudNativePG

The operator, and the Barman Cloud plugin that backs up its databases to the bucket `cnpg` on SeaweedFS. The plugin runs
next to the operator; its certificates come from cert-manager.

A database app has `templates/database-backup.yaml` with an ObjectStore and a ScheduledBackup, the sealed Secret
`database-backup-credentials`, and the plugin in `plugins` of its Cluster. The Cluster's pod then gets a sidecar that
archives the WAL continuously and takes a base backup nightly, kept 14 days, so a database can be restored to any moment
in that time. The credentials are made in the [SeaweedFS README](../seaweedfs/README.md#credentials).

If archiving fails, the WAL stays on the database's own volume until that fills up, so check `ContinuousArchiving` in the
Cluster's status after a change.

To restore, make a new Cluster with `bootstrap.recovery.source` naming an entry in `externalClusters`, whose `plugin` has
`barmanObjectName` and `serverName` set to the name of the old Cluster. It can't write its own backups to the same path, so
give its own `plugins` entry another `serverName`.
