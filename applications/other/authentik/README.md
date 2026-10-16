# Authentik

Identity provider for the `davydehaas.dev` services, served at <https://auth.davydehaas.dev>. It is
separate from the Authentik on the home server (`davydehaas.nl`).

## Secrets

`templates/authentik-credentials.yaml` is a SealedSecret named `authentik-credentials` (namespace
`authentik`). The server, worker and the bundled PostgreSQL read it. Keys:

- `AUTHENTIK_SECRET_KEY`: cookie signing and unique user IDs. Do not change it after the first install.
- `AUTHENTIK_POSTGRESQL__PASSWORD` and `password`: the `authentik` database user. Both must be equal.
- `postgres-password`: PostgreSQL admin user.

To regenerate (this rotates the database passwords, so only before the first install), seal fresh
random values against the controller in `kube-system`:

```shell
python3 - <<'PY' | kubeseal --controller-namespace kube-system --controller-name sealed-secrets-controller --format yaml > templates/authentik-credentials.yaml
import secrets, base64, json
pw = secrets.token_hex(32)
d = {
  "AUTHENTIK_SECRET_KEY": base64.b64encode(secrets.token_bytes(60)).decode(),
  "AUTHENTIK_POSTGRESQL__PASSWORD": pw,
  "password": pw,
  "postgres-password": secrets.token_hex(32),
}
print(json.dumps({"apiVersion": "v1", "kind": "Secret", "metadata": {"name": "authentik-credentials", "namespace": "authentik"}, "type": "Opaque", "stringData": d}))
PY
```

## First login

Open <https://auth.davydehaas.dev/if/flow/initial-setup/> to set the `akadmin` password.

## OIDC clients

`templates/blueprints.yaml` renders one Authentik blueprint per client (a key of the `authentik-blueprints` ConfigMap)
that creates an OAuth2 provider, an application and an `authentik Admins` group binding for each entry in
`oidcClients` in `values.yaml`. The slug must match the issuer URL (`/application/o/<slug>/`) in the
app's `SecurityPolicy`.

The client ID and secret of each client are read from the SealedSecret `authentik-oidc-clients`
(`<SLUG>_CLIENT_ID` and `<SLUG>_CLIENT_SECRET`, with `-` as `_`) and must equal the `client-id` and
`client-secret` of the `oidc-credentials` SealedSecret in the app's namespace. Generate and seal all of
them in one go, generating the random values inside the script and piping them straight to `kubeseal`
(controller in `kube-system`), so they stay equal and are never printed. Re-sealing rotates every client.

To add a client, add an entry to `oidcClients` and seal a new pair into both secrets. Argo CD
(`argocd-authentik-oidc`, keys `clientID`/`clientSecret`) and Prometheus were first created by hand in
the UI. The blueprint adopts their applications by slug and points them at a new provider, so delete
the old, now unused provider in the UI.
