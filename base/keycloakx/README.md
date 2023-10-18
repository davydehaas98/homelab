# Create user and database
```
echo $(kubectl get secret --namespace postgresql postgresql-credentials -o jsonpath="{.data.postgres-password}" | base64 -d)

kubectl exec -it postgresql-0 -n postgresql -- psql -U postgres
```

```
CREATE DATABASE keycloak;
CREATE USER keycloak WITH ENCRYPTED PASSWORD '<PASSWORD>';
GRANT ALL PRIVILEGES ON DATABASE keycloak TO keycloak;
ALTER DATABASE keycloak OWNER TO keycloak;
```

# Sealed secret
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
--format yaml > sealed-secret.yaml

cat sealed-secret.yaml
```
