# Grafana

Sealed with the command in the [root README](../../../README.md#secrets):

- `templates/grafana-credentials.yaml`: Secret `grafana-credentials`, keys `admin-user` and `admin-password`.
- `templates/grafana-oauth-credentials.yaml`: Secret `grafana-oauth-credentials`, keys `client_id` and `client_secret`
  of the Authentik client `grafana`, see the [Authentik README](../../security/authentik/README.md#oidc-clients).
