# Sealed secret
```
cat <<EOF> secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: minio-credentials
  namespace: minio
stringData:
  rootPassword:
  rootUser:
EOF
```
```
cat <<EOF> secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: loki-credentials
  namespace: minio
stringData:
  secretKey:
EOF
```
```
cat secret.yaml | kubeseal \
--controller-namespace sealed-secrets \
--controller-name sealed-secrets-controller \
--format yaml > sealed-secret.yaml

cat sealed-secret.yaml
```
