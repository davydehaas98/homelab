# Argo CD

Sealed with the command in the [root README](../../../README.md#secrets):

- `templates/homelab-repo-ssh-key.yaml`: Secret `homelab-repo-ssh-key`, label `argocd.argoproj.io/secret-type: repository`,
  keys `type` (`git`), `url` (`git@github.com:davydehaas98/homelab.git`) and `sshPrivateKey` (a deploy key of the repo).
- `templates/argocd-oidc-credentials.yaml`: Secret `argocd-oidc-credentials`, keys `client-id` and `client-secret`, see the
  [Authentik README](../../security/authentik/README.md#oidc-clients).

These only decrypt with the controller's key; restore it before rebuilding the cluster, see
[`talos/README.md`](../../../talos/README.md#sealed-secrets-keys).
