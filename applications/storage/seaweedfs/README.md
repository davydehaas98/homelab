# SeaweedFS

S3-compatible object storage (Apache-2.0), replacing MinIO whose images are no longer public.
One all-in-one pod (master, volume server, filer and S3 gateway) with its data on the `nfs`
StorageClass. S3 endpoint inside the cluster: `http://seaweedfs-all-in-one.seaweedfs:8333`.

## Credentials

`templates/seaweedfs-s3-config.yaml` is a SealedSecret holding the S3 identity config (key
`seaweedfs_s3_config`, JSON with the `loki` identity). Loki reads the same access and secret key
from `applications/monitoring/loki/templates/loki-s3-credentials.yaml`, so both secrets must be
regenerated together. Seal both against the controller in `kube-system`:

```shell
python3 - <<'PY'
import json, secrets, subprocess
access, secret = "loki", secrets.token_hex(32)
def seal(obj, out):
    r = subprocess.run(["kubeseal", "--controller-namespace", "kube-system",
      "--controller-name", "sealed-secrets-controller", "--format", "yaml"],
      input=json.dumps(obj), capture_output=True, text=True, check=True)
    open(out, "w").write(r.stdout)
cfg = {"identities": [{"name": "loki", "credentials": [{"accessKey": access, "secretKey": secret}],
       "actions": ["Read", "Write", "List", "Tagging"]}]}
seal({"apiVersion": "v1", "kind": "Secret", "type": "Opaque",
      "metadata": {"name": "seaweedfs-s3-config", "namespace": "seaweedfs"},
      "stringData": {"seaweedfs_s3_config": json.dumps(cfg)}},
     "applications/storage/seaweedfs/templates/seaweedfs-s3-config.yaml")
seal({"apiVersion": "v1", "kind": "Secret", "type": "Opaque",
      "metadata": {"name": "loki-s3-credentials", "namespace": "loki"},
      "stringData": {"S3_ACCESS_KEY": access, "S3_SECRET_KEY": secret}},
     "applications/monitoring/loki/templates/loki-s3-credentials.yaml")
PY
```

Run it from the repository root. Buckets (`loki-chunks`, `loki-ruler`, `loki-admin`) are created by the
chart's post-install hook.
