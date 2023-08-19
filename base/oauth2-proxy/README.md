```
cat <<EOF > secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: oauth2-proxy-credentials
  namespace: oauth2-proxy
type: Opaque
stringData:
  client-id: oauth2-proxy
  client-secret:
  cookie-secret:
EOF

cat secret.yaml | kubeseal \
--controller-namespace sealed-secrets \
--controller-name sealed-secrets-controller \
--format yaml > sealed-secret.yaml

cat sealed-secret.yaml
```
## Create client app with Keycloak
Manage -> Clients -> Create client
Client type: OpenID Connect
Client ID: oauth2-proxy
Access Type: confidential
Valid redirect URLs: https://auth.cloud.davydehaas.dev/oauth2/callback
