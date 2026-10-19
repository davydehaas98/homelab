---
name: add-app
description: Use when adding a new app to the cluster (a new directory under kubernetes/). Checklist of everything a new app needs, including the files that are easy to forget.
---

# Add an app

Read `AGENTS.md` and, for single-container apps, `kubernetes/_library/app/README.md` first. Work through every step and
tick each off before reporting the app as done.

1. **Start from `kubernetes/_base/`.** Copy the whole directory, including `templates/namespace.yaml`; Argo CD does not
   create namespaces, so an app without one fails to sync. Fill in every blank in the copy (chart name, namespace
   name). The namespace equals `namespace:` in `chart/values.yaml`, else the app name.
2. **Library app** (single container): `Chart.yaml` with the `app` dependency, `templates/app.yaml` with
   `{{ include "app.resources" . }}`, the rest in `values.yaml`. **Upstream chart**: the chart as a dependency.
3. **Register it** in `chart/values.yaml` under `applications.<group>.<app>` with `deploy: true`, in alphabetical order. Add `namespace:` and
   the other keys from `chart/README.md` where needed.
4. **Image**: it must publish `linux/arm64`; check the manifest, not the name. Pin a version tag Renovate can follow.
5. **Exposure**: an `HTTPRoute` on Gateway `envoy-gateway` (`sectionName: web-https`) and a DNS record in
   `terraform/cloudflare/davydehaas.dev/dns_record.tf` (`kubernetes_apps`, or `kubernetes_aliases` for aliases).
6. **Login**: Authentik OIDC, or the app's own; see `kubernetes/security/authentik/README.md`. Commit the sealed
   credentials in the same change as the policy.
7. **Storage and monitoring**: a volume as in the library README (iSCSI for SQLite and databases), and a
   ServiceMonitor, PodMonitor or dashboard ConfigMap when the app exposes metrics.
8. **Validate** as in `AGENTS.md`. When `helm` is missing locally, run it in the devcontainer (`podman exec`).
   Render the app and the root `chart/`, and confirm the render contains a Namespace.
9. **Stage only this app's files** (never commit); other uncommitted changes stay out.

After it syncs, check the Application is `Synced` and `Healthy` and the HTTPRoute is `Accepted`.
