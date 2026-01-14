# Sealed secret
```
cat <<EOF > secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: grafana-credentials
  namespace: grafana
type: Opaque
stringData:
  admin-password:
  admin-user:
EOF
```
```
cat <<EOF > secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: grafana-oauth-credentials
  namespace: grafana
type: Opaque
stringData:
  client-id:
  client-secret:
EOF
```
```
cat secret.yaml | kubeseal \
--controller-namespace sealed-secrets \
--controller-name sealed-secrets-controller \
--format yaml > sealed-secret.yaml

cat sealed-secret.yaml
```
