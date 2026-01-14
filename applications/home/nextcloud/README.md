# Create user and database
```
echo $(kubectl get secret --namespace postgresql postgresql-credentials -o jsonpath="{.data.postgres-password}" | base64 -d)

kubectl exec -it postgresql-0 -n postgresql -- psql -U postgres
```

```
CREATE DATABASE nextcloud;
CREATE USER nextcloud WITH ENCRYPTED PASSWORD '<PASSWORD>';
GRANT ALL PRIVILEGES ON DATABASE nextcloud TO nextcloud;
ALTER DATABASE nextcloud OWNER TO nextcloud;
```

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
