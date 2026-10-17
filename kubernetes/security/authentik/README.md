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

Each client's ID and secret are in its own SealedSecret `authentik-oidc-<slug>`
(`templates/oidc-client-<slug>.yaml`, keys `<SLUG>_CLIENT_ID` and `<SLUG>_CLIENT_SECRET`, with `-` as `_`),
which the server and worker load through `authentik.global.envFrom`. They must equal the `client-id` and
`client-secret` of the app's own SealedSecret in its namespace. Generate the random values inside a script
and pipe them straight to `kubeseal` (controller in `kube-system`), so both stay equal and are never printed.

To add a client, add an entry to `oidcClients`, seal its pair into `templates/oidc-client-<slug>.yaml` and the
app's secret, and add `authentik-oidc-<slug>` to `envFrom` in `values.yaml` (the render fails if that line is
missing). Then restart `authentik-worker`: blueprints read the credentials from the environment at start. Argo CD
(`argocd-authentik-oidc`, keys `clientID`/`clientSecret`) and Prometheus were first created by hand in
the UI. The blueprint adopts their applications by slug and points them at a new provider, so delete
the old, now unused provider in the UI.
