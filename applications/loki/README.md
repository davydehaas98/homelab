# Sealed secret
```
cat <<EOF> secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: loki-s3-credentials
  namespace: loki
stringData:
  S3_ACCESS_KEY:
  S3_SECRET_KEY:
EOF
```
```
cat secret.yaml | kubeseal \
--controller-namespace sealed-secrets \
--controller-name sealed-secrets-controller \
--format yaml > sealed-secret.yaml

cat sealed-secret.yaml
```
