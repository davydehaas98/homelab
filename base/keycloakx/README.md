```
cat <<EOF > secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: keycloakx-credentials
  namespace: keycloakx
type: Opaque
stringData:
  keycloak-admin:
  keycloak-admin-password:
  password:
EOF

cat secret.yaml | kubeseal \
--controller-namespace sealed-secrets \
--controller-name sealed-secrets-controller \
--format yaml > sealed-secret.yaml

cat sealed-secret.yaml
```
