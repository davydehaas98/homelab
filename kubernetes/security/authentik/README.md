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

1. Add the entry to `oidcClients`, with `namespace` when the app's is not the slug, and to `envFrom` the app's Secret
   `<slug>-oidc-credentials` with the prefix `<slug>-` (the render fails without it).
2. Seal a random pair into that Secret, which kubernetes-replicator copies here, from this folder in the dev container:

   ```shell
   sh seal-oidc-client.sh -s <slug> -n <namespace> -a <group>/<app>
   ```

The changed `envFrom` restarts the server and worker, and the worker applies the blueprints at start. An app whose
Secret has another name or other keys, no replicator annotations, or a `namespace` in `oidcClients` that does not match,
has no credentials here.

The Argo CD and Prometheus applications were made by hand first; their blueprints adopted them, so remove their old,
unused providers in the UI.
