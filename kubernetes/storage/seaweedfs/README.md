# SeaweedFS

S3 storage for Loki, Velero, talos-backup and the CloudNativePG databases: one all-in-one pod with its data on `tank`,
endpoint `http://seaweedfs-all-in-one.seaweedfs:8333`. The chart's post-install hook creates the buckets.

## Credentials

The identities `loki`, `velero`, and `talos-backup` and `cnpg` (each limited to its bucket) are in SealedSecrets,
regenerated together (this rotates all four). The S3 gateway reads them at start, so restart the pod after the sync. From
the repository root:

```shell
loki=$(openssl rand -hex 32) velero=$(openssl rand -hex 32) tb=$(openssl rand -hex 32) cnpg=$(openssl rand -hex 32)
seal() { kubeseal --controller-namespace kube-system --controller-name sealed-secrets-controller --format yaml > "$1"; }
secret() {
  jq -n --arg name "$1" --arg ns "$2" --argjson data "$3" \
    '{apiVersion: "v1", kind: "Secret", type: "Opaque", metadata: {name: $name, namespace: $ns}, stringData: $data}'
}
config=$(jq -nc --arg loki "$loki" --arg velero "$velero" --arg tb "$tb" --arg cnpg "$cnpg" '
  def identity($access; $secret; $actions): {name: $access, credentials: [{accessKey: $access, secretKey: $secret}], actions: $actions};
  {identities: [identity("loki"; $loki; ["Read", "Write", "List", "Tagging"]), identity("velero"; $velero; ["Read", "Write", "List", "Tagging"]),
    identity("talos-backup"; $tb; ["Read:talos-backup", "Write:talos-backup", "List:talos-backup", "Tagging:talos-backup"]),
    identity("cnpg"; $cnpg; ["Read:cnpg", "Write:cnpg", "List:cnpg", "Tagging:cnpg"])]}')
secret seaweedfs-s3-config seaweedfs "$(jq -n --arg c "$config" '{seaweedfs_s3_config: $c}')" \
  | seal kubernetes/storage/seaweedfs/templates/seaweedfs-s3-config.yaml
secret loki-s3-credentials loki "$(jq -n --arg s "$loki" '{S3_ACCESS_KEY: "loki", S3_SECRET_KEY: $s}')" \
  | seal kubernetes/monitoring/loki/templates/loki-s3-credentials.yaml
secret velero-credentials velero "$(jq -n --arg s "$velero" '{cloud: "[default]\naws_access_key_id=velero\naws_secret_access_key=\($s)\n"}')" \
  | seal kubernetes/storage/velero/templates/velero-credentials.yaml
secret talos-backup-s3-credentials talos-backup "$(jq -n --arg s "$tb" '{"access-key": "talos-backup", "secret-key": $s}')" \
  | seal kubernetes/core/talos-backup/templates/s3-credentials.yaml
for app in airtrail immich nextcloud; do
  secret database-backup-credentials "$app" "$(jq -n --arg s "$cnpg" '{ACCESS_KEY_ID: "cnpg", ACCESS_SECRET_KEY: $s}')" \
    | seal "kubernetes/home/$app/templates/database-backup-credentials.yaml"
done
unset loki velero tb cnpg config
```
