# Grafana

Sealed with the command in the [root README](../../../README.md#secrets):

- `templates/grafana-credentials.yaml`: Secret `grafana-credentials`, keys `admin-user` and `admin-password`.
- `templates/grafana-oidc-credentials.yaml`: Secret `grafana-oidc-credentials`, keys `client-id` and `client-secret`
  of the Authentik client `grafana`, see the [Authentik README](../../security/authentik/README.md#oidc-clients).
