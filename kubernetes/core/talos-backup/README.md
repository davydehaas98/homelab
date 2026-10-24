# talos-backup

Snapshots etcd daily, encrypts them with age and uploads them to the `talos-backup` bucket on SeaweedFS.

- **Talos API access** for the pods comes from `talos/patches/controlplane.yaml`.
- **Encryption:** `agePublicKey` in `values.yaml`; the private key is in 1Password. Without it the snapshots cannot be
  read.
- **Bucket credentials:** the identity `talos-backup` on SeaweedFS, sealed here as `talos-backup-s3-credentials`
  (`access-key`, `secret-key`), see the [SeaweedFS README](../../storage/seaweedfs/README.md).

Restore: decrypt a snapshot with `age -d -i <private key>` and decompress it (`ENABLE_COMPRESSION`), then
`talosctl bootstrap --recover-from=<snapshot>`.
