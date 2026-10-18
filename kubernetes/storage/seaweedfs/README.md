# SeaweedFS

S3 storage for Loki and Velero: one all-in-one pod with its data on `nfs`, endpoint
`http://seaweedfs-all-in-one.seaweedfs:8333`. The chart's post-install hook creates the buckets.

## Credentials

The identities `loki` and `velero` are in three SealedSecrets, regenerated together (this rotates both). From the
repository root:

```shell
loki=$(openssl rand -hex 32) velero=$(openssl rand -hex 32)
seal() { kubeseal --controller-namespace kube-system --controller-name sealed-secrets-controller --format yaml > "$1"; }
secret() {
  jq -n --arg name "$1" --arg ns "$2" --argjson data "$3" \
    '{apiVersion: "v1", kind: "Secret", type: "Opaque", metadata: {name: $name, namespace: $ns}, stringData: $data}'
}
config=$(jq -nc --arg loki "$loki" --arg velero "$velero" '
  def identity($access; $secret): {name: $access, credentials: [{accessKey: $access, secretKey: $secret}], actions: ["Read", "Write", "List", "Tagging"]};
  {identities: [identity("loki"; $loki), identity("velero"; $velero)]}')
secret seaweedfs-s3-config seaweedfs "$(jq -n --arg c "$config" '{seaweedfs_s3_config: $c}')" \
  | seal kubernetes/storage/seaweedfs/templates/seaweedfs-s3-config.yaml
secret loki-s3-credentials loki "$(jq -n --arg s "$loki" '{S3_ACCESS_KEY: "loki", S3_SECRET_KEY: $s}')" \
  | seal kubernetes/monitoring/loki/templates/loki-s3-credentials.yaml
secret velero-credentials velero "$(jq -n --arg s "$velero" '{cloud: "[default]\naws_access_key_id=velero\naws_secret_access_key=\($s)\n"}')" \
  | seal kubernetes/storage/velero/templates/velero-credentials.yaml
unset loki velero config
```
