# talos-backup

Not deployed. Snapshots etcd daily, encrypts them with age and uploads them to the `talos-backup` bucket on
SeaweedFS. Set `deploy: true` in `argocd.yaml` when these are done:

1. Apply `talos/patches/controlplane.yaml` to the control plane nodes (Talos API access for the pods).
2. Make an age pair with `age-keygen`, keep the private key in 1Password and set `agePublicKey` in `values.yaml`.
3. Create the bucket `talos-backup` and an identity for it on SeaweedFS, and seal its keys as
   `talos-backup-s3-credentials` (`access-key`, `secret-key`), see the [SeaweedFS README](../../storage/seaweedfs/README.md).

Restore: `talosctl bootstrap --recover-from=<snapshot>` with the decrypted snapshot.
