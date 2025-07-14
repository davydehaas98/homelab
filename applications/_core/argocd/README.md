# Sealed secret
## homelab-repo-ssh
```
cat <<EOF> secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: homelab-repo-ssh
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: git@github.com:davydehaas98/homelab.git
  sshPrivateKey: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    ...
    -----END OPENSSH PRIVATE KEY-----
EOF
```
## argocd-secret
```
cat <<EOF> secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: argocd-secret
  namespace: argocd
spec:
  stringData:
    admin.password:
    admin.passwordMtime:
    server.secretkey:
EOF
```

---

```
cat secret.yaml | kubeseal \
--controller-namespace sealed-secrets \
--controller-name sealed-secrets-controller \
--format yaml > sealed-secret.yaml

cat sealed-secret.yaml
```
