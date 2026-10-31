---
name: backups
description: Use when checking that the nightly backups ran, restoring a volume or database, or testing a restore. Covers Velero and the Barman plugin of CloudNativePG, and how to prove a restore without touching the real data.
---

# Check or restore backups

What runs is in `kubernetes/storage/velero/README.md`, `kubernetes/storage/cloudnative-pg/README.md` and
`kubernetes/core/talos-backup`. All of it is on SeaweedFS on `tank`, and Velero leaves out the claims and namespaces its
README names. Say so when it matters: losing `tank` loses these too.

## Check

Read-only. A schedule that exists proves nothing, so look at the last run of each:

- **Velero:** `backups.velero.io` (`kubectl get backup` resolves to CloudNativePG): `Completed`, no errors, and its
  `datauploads.velero.io` all `Completed`. No VolumeSnapshots may stay behind, as they count towards a volume's quota.
- **Databases:** per Cluster, `ContinuousArchiving` in its status, `serverRecoveryWindow` in the status of its
  ObjectStore (the Cluster's own `lastSuccessfulBackup` stays empty with the plugin), and `failed_count` against
  `archived_count` in `pg_stat_archiver`. A backup that fails while the pod restarts is not a fault in itself; the next
  one must complete.
- **etcd:** the last job of the `talos-backup` CronJob.
- **Room:** `df` of `/data` in SeaweedFS.

## Restore

Restore next to the real data first, also for a real recovery, and compare before replacing anything. Stopping an app or
overwriting its volume needs the user's go-ahead.

- **A volume, from Velero:** a Restore of `persistentvolumeclaims` only, with `namespaceMapping` to a test namespace, so
  no second copy of an app starts. Stop if a restored claim has a `volumeName` of a real volume (`zfs-*`). It waits until
  a pod uses the claim, so start one on `midgard-0` with its toleration. To select some claims, label them before the
  Backup, as a Restore cannot pick them by name; remove the labels afterwards.
- **A database, from Barman:** a temporary Cluster next to the real one, as in the CloudNativePG README. No `plugins` of
  its own in a test, so it does not write to the same path.
- **A database on a snapshot:** start its image on the restored claim with the settings of the real pod, on a local
  socket. It goes through crash recovery, which is expected.

## Prove it

A restore that starts proves little. Compare with the real data:

- **Databases:** the row count per table. Live tables may differ by what was written since; name them. Run `pg_amcheck`
  on the copy, which needs a writable directory. It does not read vector indexes, so for Immich compare a search too,
  with `vchordrq.probes` set.
- **SQLite:** `PRAGMA integrity_check` on the copy.
- **Files:** count, size and the checksum of a file that does not change.

Check each result means what it seems: a query that errors on both sides also compares as equal.

## Clean up

The StorageClasses `Retain`, so a test leaves data behind after its namespace and PV are gone. Deleting those is fine;
deleting the remaining ZFSVolume `pvc-*` destroys the copy, so give the user that command with the exact names of the
test's copies. Real volumes made by a StorageClass are named `pvc-*` too, so never select by that pattern.

Report what was restored and from when, what was compared, and what was not proven, such as running the app on the copy.
