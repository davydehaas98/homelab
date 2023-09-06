# Sealed secret
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
---

# Create cookie-secret
https://oauth2-proxy.github.io/oauth2-proxy/docs/configuration/overview/

Bash:
```
dd if=/dev/urandom bs=32 count=1 2>/dev/null | base64 | tr -d -- '\n' | tr -- '+/' '-_'; echo
```
---

# Create client app and client-secret in Keycloak
### Clients -> Create client

- 1 General Settings:
    - Client type: OpenID Connect
    - Client ID: oauth2-proxy
- 2 Capability config:
    - Client authentication: On

- 3 Login settings:
    - Valid redirect URLs:
        - https://grafana.cloud.davydehaas.dev/oauth2/callback
        - https://hubble.cloud.davydehaas.dev/oauth2/callback
        - https://longhorn.cloud.davydehaas.dev/oauth2/callback
        - https://prometheus.cloud.davydehaas.dev/oauth2/callback
        - Etc...

### Clients -> oauth2-proxy -> Client scopes -> oauth2-proxy-dedicated -> Mappers
- Click on 'Configure a new mapper'
    - Mapper type: Audience
    - Name: oauth2-proxy-audience
    - Included Client Audience: oauth2-proxy
    - Add to access token: ON

### Clients -> oauth2-proxy -> Credentials
- Copy 'Client secret'
  - Paste 'client-secret' in 'oauth2-proxy-credentials.yaml'
