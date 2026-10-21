---
name: add-oidc-client
description: Use when an app should be behind the Authentik login (OIDC) on its route. Covers the Authentik client, the sealed credentials, and the route policy, which must land together.
---

# Add an OIDC client

The steps and the shell are in `kubernetes/security/authentik/README.md` ("OIDC clients"). Use that, and the
`oidc` keys of the library chart (`kubernetes/_library/app/README.md`) for a library app. Zigbee2MQTT is a worked
example of an upstream chart with its own `SecurityPolicy`.

Pick the login first. A mobile app or API client cannot follow a redirect to the identity provider, so those apps keep
their own login, or use `oidc.bypassPaths` for the API paths only.

Three things must land in **one change**, as a policy without its Secret breaks the route:

1. **The client in Authentik** (`kubernetes/security/authentik/values.yaml`):
   - an entry in `oidcClients` with `name`, `slug` and `redirectURL` (the callback is `https://<host>/oauth2/callback`
     for the gateway policy; an app with native OIDC has its own path);
   - `authentik-oidc-<slug>` in `envFrom`. The render fails without it, and the `slug` upper-cased with `-` as `_`
     is the prefix of the `_CLIENT_ID` and `_CLIENT_SECRET` keys.
   - `openAccess: true` only when the app maps roles from group claims.
2. **The sealed credentials**, one random pair into both Secrets:
   `kubernetes/security/authentik/templates/oidc-client-<slug>.yaml` and
   `kubernetes/<group>/<app>/templates/oidc-credentials.yaml`. Run `seal-oidc-client.sh` in the dev container, with
   `~/.kube` mounted as `kubeseal` needs the cluster. The pair is generated in the script and never printed, so you
   may run it yourself, but never read the Secrets back.
3. **The route policy.** For a library app, `oidc.enabled: true` (and `oidc.slug` if it differs from the chart name).
   For an upstream chart, a `SecurityPolicy` in `templates/` with the issuer, authorization, token and end-session
   endpoints set explicitly (so the gateway does not fetch the discovery document), as in `zigbee2mqtt`.

After the sync, restart `authentik-worker`, since blueprints read the credentials at start. Then check the
`SecurityPolicy` is `Accepted` and the login redirects to `auth.davydehaas.dev`.

While Authentik restarts, Envoy Gateway can mark OIDC policies `Invalid` and does not retry, so their routes answer
500. Check `kubectl get securitypolicy -A` after any Authentik restart; the fix is
`kubectl -n envoy-gateway rollout restart deploy/envoy-gateway` (the controller only, the proxies keep serving), with
the user's go-ahead.

Validate with `scripts/validate.sh`, passing both the app and `security/authentik`.
