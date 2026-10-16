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
