# Sealed secret
```
cat <<EOF > secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: s3-credentials
  namespace: longhorn-system
type: Opaque
stringData:
  AWS_ACCESS_KEY_ID:
  AWS_ENDPOINTS:
  AWS_SECRET_ACCESS_KEY:
EOF

cat secret.yaml | kubeseal \
--controller-namespace sealed-secrets \
--controller-name sealed-secrets-controller \
--format yaml > sealed-secret.yaml

cat sealed-secret.yaml
```
