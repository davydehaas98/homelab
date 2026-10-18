# Authentik

Identity provider at <https://auth.davydehaas.dev>, separate from the home server's Authentik (`davydehaas.nl`). On
a new install, set the `akadmin` password at <https://auth.davydehaas.dev/if/flow/initial-setup/>.

## Secrets

`templates/authentik-credentials.yaml` is Secret `authentik-credentials`, read by the server, worker and Postgres:

- `AUTHENTIK_SECRET_KEY`: signs cookies and user IDs; never change it after the first install.
- `AUTHENTIK_POSTGRESQL__PASSWORD` and `password`: the `authentik` database user, equal.
- `postgres-password`: the Postgres admin.

Regenerating rotates the database passwords, so do it only before the first install, from this folder:

```shell
pw=$(openssl rand -hex 32)
jq -n --arg key "$(openssl rand -base64 60 | tr -d '\n')" --arg pw "$pw" --arg admin "$(openssl rand -hex 32)" '{
  apiVersion: "v1", kind: "Secret", type: "Opaque",
  metadata: {name: "authentik-credentials", namespace: "authentik"},
  stringData: {AUTHENTIK_SECRET_KEY: $key, AUTHENTIK_POSTGRESQL__PASSWORD: $pw, password: $pw, "postgres-password": $admin}
}' | kubeseal --controller-namespace kube-system --controller-name sealed-secrets-controller --format yaml > templates/authentik-credentials.yaml
unset pw
```

## OIDC clients

Each entry in `oidcClients` gets a blueprint with a provider, an application and an `authentik Admins` binding. Its
slug is the issuer path (`/application/o/<slug>/`) in the app's `SecurityPolicy`. To add one:

1. Add the entry to `oidcClients`, and `authentik-oidc-<slug>` to `envFrom` (the render fails without it).
2. Seal one random pair into both Secrets, from this folder:

   ```shell
   slug=<slug> ns=<namespace> app=<group>/<app>
   env=$(echo "$slug" | tr 'a-z-' 'A-Z_')
   id=$(openssl rand -hex 20) secret=$(openssl rand -hex 32)
   seal() { kubeseal --controller-namespace kube-system --controller-name sealed-secrets-controller --format yaml; }
   secret() {
     jq -n --arg name "$1" --arg ns "$2" --arg idKey "$3" --arg secretKey "$4" --arg id "$id" --arg secret "$secret" \
       '{apiVersion: "v1", kind: "Secret", type: "Opaque", metadata: {name: $name, namespace: $ns}, stringData: {($idKey): $id, ($secretKey): $secret}}'
   }
   secret "authentik-oidc-$slug" authentik "${env}_CLIENT_ID" "${env}_CLIENT_SECRET" | seal > "templates/oidc-client-$slug.yaml"
   secret "$slug-oidc-credentials" "$ns" client-id client-secret | seal > "../../$app/templates/oidc-credentials.yaml"
   unset id secret
   ```

3. After the sync, restart `authentik-worker`: blueprints read the credentials at start.

The Argo CD (`argocd-authentik-oidc`, keys `clientID`/`clientSecret`) and Prometheus applications were made by hand
first; their blueprints adopted them, so remove their old, unused providers in the UI.
