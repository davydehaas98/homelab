# AGENTS.md

This file provides guidance to AI coding agents (e.g. Claude Code) when working with code in this repository.

## Overview

GitOps repo for a homelab Kubernetes cluster: Talos OS on 4x Turing RK1 nodes (`jotunheim_0`–`3`, cluster `yggdrasil`), Cilium CNI, and Argo CD syncing everything under `kubernetes/` from `main` of `github.com/davydehaas98/homelab`. Anything merged to `main` is what the cluster converges to, so changes here are deployments.

## How applications get deployed (app-of-apps)

1. `kubernetes/core/argocd/templates/applications.yaml` defines the root Argo CD `Application`, which renders the Helm chart in `chart/`.
2. `chart/templates/applications.yaml` loops over `chart/values.yaml` (`applications.<group>.<app>`) and emits one Argo CD `Application` per entry with `deploy: true`, pointing at `kubernetes/<group>/<app>`.
3. Each `kubernetes/<group>/<app>/` is a small wrapper Helm chart: `Chart.yaml` pulls the upstream chart as a dependency, `values.yaml` holds overrides nested under the dependency name, and `templates/` holds extra manifests (namespace, SealedSecrets, VPAs, routes, etc.).

Consequences:

- **A directory under `kubernetes/` does nothing on its own.** It must also be listed in `chart/values.yaml` with `deploy: true`. Some app directories (e.g. `media/plex`, `home/immich`, `security/kyverno`) are not listed and therefore not deployed; listed apps with `deploy: false` are scaffolds that are switched off.
- The directory name must equal the kebab-cased key in `chart/values.yaml` (or its `nameOverride`), and the group directory must equal the group key.
- Namespace defaults to the app name; override with `namespace:` in `chart/values.yaml`.
- Apps auto-sync (AppProject `always-sync`) unless they set `autoSync: false`, which puts them in AppProject `no-sync`, whose deny sync window blocks automatic syncs (manual sync still allowed). Core pieces like `argocd`, `cilium`, and `longhorn` are deliberately `no-sync`.
- Per-app knobs (`ignoreDifferences`, `serverSideApply`) are documented in `chart/README.md`.

To add an app: copy `kubernetes/_base/` (an empty scaffold with `Chart.yaml` + `templates/namespace.yaml`) into `kubernetes/<group>/<app>/`, fill in the dependency, then add the entry to `chart/values.yaml`.

## Secrets

Secrets are committed only as Bitnami SealedSecrets (controller `sealed-secrets-controller`, namespace `kube-system`). See `kubernetes/core/argocd/README.md` for the `kubeseal` workflow. Never commit plaintext `Secret` manifests. SealedSecrets are bound to their name and namespace; to add keys without rotating existing credentials, read the live Secret with `kubectl`, merge, and re-seal. Never print secret values. `talos/gen/` (cluster secrets and generated machine configs) and `talos/talosconfig` are gitignored and must stay that way.

## How the pieces connect

- **Traffic.** External traffic reaches the cluster through the home server's reverse proxy (TLS passthrough, defined in the separate `home-server` repo) and then the Envoy Gateway LoadBalancer. An app is published with an `HTTPRoute` attached to the shared `envoy-gateway` Gateway (`sectionName: web-https`), and external-dns creates the DNS record from the route. Do not add Ingress objects.
- **Sync flags.** `chart/templates/applications.yaml` adds the Argo CD `ServerSideDiff` annotation to every app with `serverSideApply: true`; without it, defaults added by the API server (for example on HTTPRoutes) show up as a permanent `OutOfSync`.
- **Logins.** Authentik is the identity provider: a gateway `SecurityPolicy` (OIDC) on the route, native OIDC in the app, or the app's own login. To add a client:
  1. Add it to `oidcClients` in `kubernetes/security/authentik/values.yaml` (one blueprint is generated per entry).
  2. Seal the same credentials into `authentik-oidc-clients` (`<SLUG>_CLIENT_ID` / `_CLIENT_SECRET`) and into the app's own secret.
  3. Restart `authentik-worker` after the secret changes: blueprints read their credentials from the environment at start.

  Ship the sealed secrets in the same commit as the policy, because a `SecurityPolicy` that points at a missing secret blocks its route. See `kubernetes/security/authentik/README.md`.
- **Storage and hardware.** The default StorageClass is NFS, served by the home server; the exports are managed there, not in this repo. Nodes are arm64 and boot from small eMMC disks. Their NVMe drives sit on the PCI bus but expose no block device to Talos, so there is currently no data disk and node-local storage systems (such as Longhorn) are not an option until that is fixed (see `talos/NVME-INVESTIGATION.md`). Images must publish arm64.
- **Monitoring.** Prometheus runs with every `*SelectorNilUsesHelmValues: false`, so ServiceMonitors and PodMonitors are picked up from all namespaces. Its CRDs come from the separate `prometheus-crd` app, whose version must match the operator in the Prometheus chart. Grafana's sidecar only reads ConfigMaps from its own namespace, so charts that ship dashboards must create them there.
- **App styles.** Simple apps either use the `bjw-s` `app-template` chart as their dependency, or hand-written templates (`_helpers.tpl`, `statefulset.yaml`, `service.yaml`, `route.yaml`) with no chart dependency, for example `kubernetes/media/sonarr`.

## Commands

CI checks live in `.github/workflows/`: `helm.yaml` (pull requests), `ansible.yaml` and `terraform-cloudflare.yaml`.

### Helm

Render and lint a wrapper chart:

```sh
helm dependency update kubernetes/<group>/<app>
helm lint kubernetes/<group>/<app>
helm template kubernetes/<group>/<app>
```

Render the generated Argo CD Applications to check `chart/values.yaml` edits:

```sh
helm template chart
```

### Validating a change

- Validate a change the way CI does (`helm.yaml` runs this on pull requests): render `chart/`, then for each changed app run `helm dependency update`, `helm lint` and `helm template --api-versions monitoring.coreos.com/v1`. The flag is needed because some charts refuse to render without the Prometheus Operator API.
- To check a render against the live cluster, pipe it into `kubectl apply --dry-run=server -f -`. Kinds whose CRDs are not installed yet fail by design, and very large objects trip client-side apply's annotation limit (see `serverSideApply`).

### Ansible

```sh
pip install -r requirements.txt && ansible-galaxy install -r requirements.yaml
cd ansible && ansible-playbook playbook.yaml --syntax-check
ansible-lint ./ansible/playbook.yaml --profile moderate
```

### Terraform (`terraform/`)

These need no credentials:

```sh
terraform init -backend=false
terraform validate
terraform fmt -check
```

The state is in S3, and CI assumes an AWS role whose trust policy is defined outside this repo (see `terraform/README.md`).

## Talos (`talos/`)

Scripts are run from inside `talos/` (paths like `gen/`, `patches/` are relative). `talos/README.md` is the full bootstrap runbook (image build, flashing via `tpi`, config generation, bootstrap, then manual Cilium/sealed-secrets/Argo CD install before GitOps takes over).

- Machine config = `talosctl gen config` + patches: `<board>/nodes/<node>.yaml` → `patches/cluster.yaml` → `patches/controlplane.yaml` (control plane only). Board-specific scripts (image/schematic generation, flashing) live in `talos/rk1/`.
- `apply-config.sh -b rk1 -c <cluster> -n <node> -t controlplane|worker` regenerates and applies a node config.
- `upgrade-talos.sh -b rk1 -c <talosconfig> -n <node> -v <version>` upgrades a node using its factory schematic image.

## Other directories

- `ansible/`: kubeadm-on-Ubuntu provisioning (roles for kernel, containerd, Kubernetes, control plane/worker join). Predates the Talos setup; `SETUP.md` and `scripts/commands.md` are the manual equivalents.
- `terraform/`: Terraform stacks outside the cluster, for now the Cloudflare DNS of `davydehaas.dev` (`terraform/README.md`). State is in S3, `.github/workflows/terraform-cloudflare.yaml` plans on push and applies only when run by hand. Never commit `*.tfvars` or state files.
- `disabled/`: manifests intentionally kept out of the sync path.

## Dependency updates

Helm chart and image versions are bumped by Renovate (`.github/renovate.json`); patch and digest updates automerge.
