# Authentik

Identity provider at <https://auth.davydehaas.dev>. On a new install, set the `akadmin` password at
<https://auth.davydehaas.dev/if/flow/initial-setup/>.

## Secrets

`templates/authentik-credentials.yaml` is Secret `authentik-credentials` with `AUTHENTIK_SECRET_KEY`, which signs
cookies and user IDs; never change it after the first install. To generate it, only before the first install, from this
folder:

```shell
jq -n --arg key "$(openssl rand -base64 60 | tr -d '\n')" '{
  apiVersion: "v1", kind: "Secret", type: "Opaque",
  metadata: {name: "authentik-credentials", namespace: "authentik"},
  stringData: {AUTHENTIK_SECRET_KEY: $key}
}' | kubeseal --controller-namespace kube-system --controller-name sealed-secrets-controller --format yaml > templates/authentik-credentials.yaml
```

## Database

PostgreSQL run by CloudNativePG (`templates/database.yaml`), which makes the database password in the Secret
`authentik-database-app`. Its backups are in `templates/database-backup.yaml`, see
[CloudNativePG](../../storage/cloudnative-pg/README.md).

## OIDC clients

Each entry in `oidcClients` gets a blueprint with a provider, an application and an `authentik Admins` binding. Its
slug is the issuer path (`/application/o/<slug>/`) in the app's `SecurityPolicy`. To add one:

1. Add the entry to `oidcClients`, and `authentik-oidc-<slug>` to `envFrom` (the render fails without it).
2. Seal one random pair into both Secrets, from this folder in the dev container:

   ```shell
   sh seal-oidc-client.sh -s <slug> -n <namespace> -a <group>/<app>
   ```

3. After the sync, restart `authentik-worker`: blueprints read the credentials at start.

The Argo CD and Prometheus applications were made by hand first; their blueprints adopted them, so remove their old,
unused providers in the UI.
