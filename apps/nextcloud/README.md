# Sealed secret
```
cat <<EOF > secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: nextcloud-credentials
  namespace: nextcloud
type: Opaque
stringData:
  username:
  password:
  postgres-username:
  postgres-password:
EOF

cat secret.yaml | kubeseal \
--controller-namespace sealed-secrets \
--controller-name sealed-secrets-controller \
--format yaml > sealed-secret.yaml

cat sealed-secret.yaml
```
