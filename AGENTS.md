# AGENTS.md

This file provides guidance to AI coding agents (e.g. Claude Code) when working with code in this repository.

## Overview

GitOps repo for a homelab Kubernetes cluster: Talos OS on 4x Turing RK1 nodes (`jotunheim_0`–`3`, cluster `yggdrasil`), Cilium CNI, and Argo CD syncing everything under `kubernetes/` from `main` of `github.com/davydehaas98/homelab`. Anything merged to `main` is what the cluster converges to, so changes here are deployments.

## How applications get deployed (app-of-apps)

1. `kubernetes/core/argocd/templates/applications.yaml` defines the root Argo CD `Application`, which renders the Helm chart in `chart/`.
2. `chart/templates/applications.yaml` loops over `chart/values.yaml` (`applications.<group>.<app>`) and emits one Argo CD `Application` per entry with `deploy: true`, pointing at `kubernetes/<group>/<app>`.
3. Each `kubernetes/<group>/<app>/` is a small wrapper Helm chart: `Chart.yaml` pulls the upstream chart as a dependency, `values.yaml` holds overrides nested under the dependency name, and `templates/` holds extra manifests (namespace, SealedSecrets, VPAs, routes, etc.).

Consequences:
- **A directory under `kubernetes/` does nothing on its own.** It must also be listed in `chart/values.yaml` with `deploy: true`. Several app directories (e.g. `media/*`, `home/immich`, `security/kyverno`) are not listed and therefore not deployed.
- The directory name must equal the kebab-cased key in `chart/values.yaml` (or its `nameOverride`), and the group directory must equal the group key.
- Namespace defaults to the app name; override with `namespace:` in `chart/values.yaml`.
- Apps auto-sync (AppProject `always-sync`) unless they set `autoSync: false`, which puts them in AppProject `no-sync`, whose deny sync window blocks automatic syncs (manual sync still allowed). Core pieces like `argocd`, `cilium`, and `longhorn` are deliberately `no-sync`.
- Per-app knobs (`ignoreDifferences`, `serverSideApply`) are documented in `chart/README.md`.

To add an app: copy `kubernetes/_base/` (an empty scaffold with `Chart.yaml` + `templates/namespace.yaml`) into `kubernetes/<group>/<app>/`, fill in the dependency, then add the entry to `chart/values.yaml`.

## Secrets

Secrets are committed only as Bitnami SealedSecrets (controller `sealed-secrets-controller`, namespace `kube-system`). See `kubernetes/core/argocd/README.md` for the `kubeseal` workflow. Never commit plaintext `Secret` manifests. `talos/gen/` (cluster secrets and generated machine configs) and `talos/talosconfig` are gitignored and must stay that way.

## Commands

Render/lint a wrapper chart (from the app directory):
```sh
helm dependency update kubernetes/<group>/<app>
helm lint kubernetes/<group>/<app>
helm template kubernetes/<group>/<app>
```

Render the generated Argo CD Applications to check `chart/values.yaml` edits:
```sh
helm template chart
```

Ansible (the only CI check — `.github/workflows/ansible.yaml`):
```sh
pip install -r requirements.txt && ansible-galaxy install -r requirements.yaml
cd ansible && ansible-playbook playbook.yaml --syntax-check
ansible-lint ./ansible/playbook.yaml --profile moderate
```

## Talos (`talos/`)

Scripts are run from inside `talos/` (paths like `gen/`, `patches/` are relative). `talos/README.md` is the full bootstrap runbook (image build, flashing via `tpi`, config generation, bootstrap, then manual Cilium/sealed-secrets/Argo CD install before GitOps takes over).

- Machine config = `talosctl gen config` + patches: `<board>/nodes/<node>.yaml` → `patches/cluster.yaml` → `patches/controlplane.yaml` (control plane only). Board-specific scripts (image/schematic generation, flashing) live in `talos/rk1/`.
- `apply-config.sh -b rk1 -c <cluster> -n <node> -t controlplane|worker` regenerates and applies a node config.
- `upgrade-talos.sh -b rk1 -c <talosconfig> -n <node> -v <version>` upgrades a node using its factory schematic image.

## Other directories

- `ansible/`: kubeadm-on-Ubuntu provisioning (roles for kernel, containerd, Kubernetes, control plane/worker join). Predates the Talos setup; `SETUP.md` and `scripts/commands.md` are the manual equivalents.
- `disabled/`: manifests intentionally kept out of the sync path.
- Dependency versions (Helm charts, images) are bumped by Renovate (`.github/renovate.json`); patch/digest updates automerge.
