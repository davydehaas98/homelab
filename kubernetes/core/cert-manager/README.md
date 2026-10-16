# Sealed secret
```
cat <<EOF > secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: cloudflare-api-token
  namespace: cert-manager
type: Opaque
stringData:
  api-token:
EOF

cat secret.yaml | kubeseal \
--controller-namespace sealed-secrets \
--controller-name sealed-secrets-controller \
--format yaml > sealed-secret.yaml

cat sealed-secret.yaml
```
