# AGENTS.md

Guidance for AI coding agents in this repository.

GitOps repo for the homelab cluster `yggdrasil`: Talos on 4x Turing RK1 nodes (`jotunheim-0`–`3`, arm64) and the
storage node `midgard-0` (amd64), Cilium, and Argo CD syncing `kubernetes/` from `main`. A merge to `main` is a
deployment.

## Apps

- The ApplicationSet in `kubernetes/core/argocd/templates/applicationset.yaml` makes one Application per
  `kubernetes/<group>/<app>/argocd.yaml` with `deploy: true`. A directory without it is not deployed. `deploy: false`
  or removing the file leaves the workloads running, as the Applications have no finalizer.
- The namespace is the app name unless `namespace:` is set in `argocd.yaml`. Its other keys are in
  `kubernetes/README.md`; `autoSync: false` turns off automated sync (manual sync only), as for `cilium`.
- Each app is a wrapper chart: the upstream chart as a dependency, its overrides in `values.yaml`, and extra
  manifests in `templates/`. Single-container apps use the library chart `kubernetes/_library/app` instead and
  only set values (see its README). New apps start from a copy of `kubernetes/_base/`, following the `add-app` skill.
- Images must publish the architecture of their node: amd64 for an app with a volume, which runs on `midgard-0`, and
  arm64 for the rest, which run on the RK1 nodes.
- YAML style: `resources` with `limits` before `requests` and keys alphabetical, memory in `Mi` below 1Gi and `Gi`
  from there, double quotes, indented sequences. Templates are not linted, so keep to it there too.

## Secrets

- Commit secrets only as SealedSecrets (controller `sealed-secrets-controller` in `kube-system`), never plaintext.
  Seal from stdin and never print values. To add keys, merge them into the live Secret and re-seal, as a
  SealedSecret is bound to its name and namespace.
- `talos/gen/` and `talos/talosconfig` hold cluster secrets and stay gitignored; don't search them. Client configs
  are `~/.talos/config` and `~/.kube/config`, outside the repo.

## How the pieces connect

- **Traffic.** The UniFi gateway forwards 80 and 443 to the Envoy Gateway (`192.168.1.56`), the entry point.
  The old domain `*.davydehaas.nl` serves Plex and redirects other names to `davydehaas.dev`
  (`nlRedirects` in `kubernetes/core/envoy-gateway/values.yaml`). Publish an app with an `HTTPRoute` on Gateway
  `envoy-gateway` (`sectionName: web-https`), no Ingress. Every hostname needs a DNS record in `terraform/cloudflare/davydehaas.dev/dns_record.tf`:
  `kubernetes_apps`, or `kubernetes_aliases` for `route.aliases`. Tools only for the home network go on Gateway
  `envoy-gateway-private` (`192.168.1.61`, not forwarded) under `*.mcp.davydehaas.dev`, with a record in
  `kubernetes_private_apps`.
- **Logins.** Authentik, through a gateway `SecurityPolicy`, the app's native OIDC, or the app's own login. Adding
  a client is in `kubernetes/security/authentik/README.md`. Ship the sealed credentials in the same commit as the
  policy: a policy without its Secret breaks the route.
- **Storage.** Volumes are ZFS datasets on `midgard-0`, see `kubernetes/storage/zfs-localpv/README.md`: StorageClass
  `zfs-fast` (default, NVMe) or `zfs-tank` (RAIDZ1, for large files). A pod with such a volume can only run there and
  must tolerate its taint, which the library chart does. The media is a `local` volume on the same node. The RK1 nodes
  have no usable data disk, so node-local storage there (Longhorn) is not an option.
- **Monitoring.** Prometheus picks up ServiceMonitors and PodMonitors from all namespaces. Its CRDs come from the
  `prometheus-crd` app, which must match the operator version. Grafana only reads dashboard ConfigMaps from its
  own namespace.
- **Sync.** Apps with `serverSideApply: true` also get the `ServerSideDiff` annotation, so defaults the API server
  adds don't show as `OutOfSync`.

## Validating

CLI versions are pinned in `mise.toml`, and the dev container (`.devcontainer/`) has them. Always run the CLIs in the
dev container, never on the host, which may lack them or have other versions. No CI checks the charts, so validate
before pushing with `scripts/validate.sh` (yamllint on the plain YAML, see `.yamllint`, and per app the dependencies,
lint and a render with a Namespace; `-t` adds the Terraform). `scripts/render-diff.sh` shows what a change does to an
app's manifests. The same scripts triage an app (`scripts/debug-app.sh`) and seal a Secret (`scripts/seal-secret.sh`).

Library charts only render through an app that uses them. `kubectl apply --dry-run=server -f -` checks a render
against the cluster.

Terraform without credentials: `terraform init -backend=false && terraform validate && terraform fmt -check`. CI
applies `cloudflare/` on a merge to `main`, and `devopsarr/` is applied by hand, see `terraform/README.md`. Never commit
`*.tfvars` or state.

## Talos

Run the scripts from `talos/`; `talos/README.md` is the runbook. A node config is `talosctl gen config` plus
`<board>/nodes/<node>.yaml`, `patches/cluster.yaml` and, for the control plane, `patches/controlplane.yaml`.
`talosctl` in `mise.toml` must equal the Talos version on the nodes.

Renovate bumps chart, image and tool versions, and automerges patch and digest updates.
