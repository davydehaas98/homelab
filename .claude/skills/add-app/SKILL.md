---
name: add-app
description: Use when adding a new app to the cluster (a new directory under kubernetes/). Checklist of everything a new app needs, including the files that are easy to forget.
---

# Add an app

Read `AGENTS.md` and, for single-container apps, `kubernetes/_library/app/README.md` first. Work through every step and
tick each off before reporting the app as done.

1. **Start from `kubernetes/_base/`.** Copy the whole directory, including `templates/namespace.yaml` and `argocd.yaml`;
   Argo CD does not create namespaces, so an app without one fails to sync. Fill in every blank in the copy (chart name, namespace
   name). The namespace equals `namespace:` in the app's `argocd.yaml`, else the app name. An app in another app's
   namespace, such as `media-server`, leaves out `namespace.yaml`.
2. **Library app** (single container): `Chart.yaml` with the `app` dependency, `templates/app.yaml` with
   `{{ include "app.resources" . }}`, the rest in `values.yaml`. **Upstream chart**: the chart as a dependency.
3. **Register it** in the copied `argocd.yaml`: `deploy: true`, plus `namespace:` and the other keys from
   `kubernetes/README.md` where needed. A new group also needs its path in the ApplicationSet's generator.
4. **Image**: it must publish the architecture of its node, `linux/amd64` with a volume and `linux/arm64` without; check
   the manifest, not the name. Pin a version tag Renovate can follow; if the image only has commit hashes, pin one and
   say in `values.yaml` that it is updated by hand. The library chart also uses the tag as a label, so no digest in it.
5. **Exposure**: an `HTTPRoute` on Gateway `envoy-gateway` (`sectionName: web-https`) and a DNS record in
   `terraform/cloudflare/davydehaas.dev/dns_record.tf` (`kubernetes_apps`, or `kubernetes_aliases` for aliases).
6. **Login**: Authentik OIDC (the `add-oidc-client` skill), or the app's own. Kyverno's `require-route-login` refuses a
   route without a login, so an app without one sets `route.auth` (library README). Commit the sealed credentials in the
   same change as the policy. Other secrets: the `seal-secret` skill.
7. **Storage and monitoring**: a volume as in the library README (`zfs-fast` by default, `zfs-tank` for large files), and
   a ServiceMonitor, PodMonitor or dashboard ConfigMap when the app exposes metrics. Velero backs up a new volume by
   itself; a claim not worth keeping gets the label `velero.io/exclude-from-backup: "true"`. A media app mounts its own
   folder of the `media` claim (`kubernetes/media-server/media-server/README.md`), which must exist with the owner of
   the media before the first deploy.
8. **Find it**: an entry in `kubernetes/tools/homepage/config/services.yaml` and a check in
   `kubernetes/tools/gatus/config/config.yaml`.
9. **Validate** with `scripts/validate.sh` (`-t` when `dns_record.tf` changed), always in the dev container
   (`.devcontainer/README.md`). It lints the YAML, renders the app and warns when the render has no Namespace (fine only
   for an app in another app's namespace).
10. **Stage only this app's files** (never commit); other uncommitted changes stay out.

After it syncs, check the Application is `Synced` and `Healthy` and the HTTPRoute is `Accepted`.
