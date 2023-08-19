```
cat <<EOF > secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: oauth-proxy-credentials
  namespace: oauth-proxy
type: Opaque
stringData:
  client-id:
  client-secret:
  cookie-secret:
EOF

cat secret.yaml | kubeseal \
--controller-namespace sealed-secrets \
--controller-name sealed-secrets-controller \
--format yaml > sealed-secret.yaml

cat sealed-secret.yaml
```
