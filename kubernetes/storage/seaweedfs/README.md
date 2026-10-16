# SeaweedFS

S3-compatible object storage (Apache-2.0), replacing MinIO whose images are no longer public.
One all-in-one pod (master, volume server, filer and S3 gateway) with its data on the `nfs`
StorageClass. S3 endpoint inside the cluster: `http://seaweedfs-all-in-one.seaweedfs:8333`.

## Credentials

`templates/seaweedfs-s3-config.yaml` is a SealedSecret holding the S3 identity config (key
`seaweedfs_s3_config`, JSON with the `loki` and `velero` identities). Loki and Velero read the same
access and secret keys from `kubernetes/monitoring/loki/templates/loki-s3-credentials.yaml` and
`kubernetes/storage/velero/templates/velero-credentials.yaml`, so all three secrets must be
regenerated together (this rotates both identities). Seal them against the controller in `kube-system`:

```shell
python3 - <<'PY'
import json, secrets, subprocess
loki = ("loki", secrets.token_hex(32))
velero = ("velero", secrets.token_hex(32))
def seal(obj, out):
    r = subprocess.run(["kubeseal", "--controller-namespace", "kube-system",
      "--controller-name", "sealed-secrets-controller", "--format", "yaml"],
      input=json.dumps(obj), capture_output=True, text=True, check=True)
    open(out, "w").write(r.stdout)
def identity(access, secret):
    return {"name": access, "credentials": [{"accessKey": access, "secretKey": secret}],
            "actions": ["Read", "Write", "List", "Tagging"]}
cfg = {"identities": [identity(*loki), identity(*velero)]}
seal({"apiVersion": "v1", "kind": "Secret", "type": "Opaque",
      "metadata": {"name": "seaweedfs-s3-config", "namespace": "seaweedfs"},
      "stringData": {"seaweedfs_s3_config": json.dumps(cfg)}},
     "kubernetes/storage/seaweedfs/templates/seaweedfs-s3-config.yaml")
seal({"apiVersion": "v1", "kind": "Secret", "type": "Opaque",
      "metadata": {"name": "loki-s3-credentials", "namespace": "loki"},
      "stringData": {"S3_ACCESS_KEY": loki[0], "S3_SECRET_KEY": loki[1]}},
     "kubernetes/monitoring/loki/templates/loki-s3-credentials.yaml")
seal({"apiVersion": "v1", "kind": "Secret", "type": "Opaque",
      "metadata": {"name": "velero-credentials", "namespace": "velero"},
      "stringData": {"cloud": f"[default]\naws_access_key_id={velero[0]}\naws_secret_access_key={velero[1]}\n"}},
     "kubernetes/storage/velero/templates/velero-credentials.yaml")
PY
```

Run it from the repository root. Buckets (`loki-chunks`, `loki-ruler`, `loki-admin`, `velero`) are created by the
chart's post-install hook.
