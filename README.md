# Homelab

Kubernetes cluster `yggdrasil` on Talos, with Cilium and Argo CD. Argo CD deploys `kubernetes/` from `main`.
Agent guidance is in [`AGENTS.md`](AGENTS.md).

## Layout

- `kubernetes/`: one Helm chart per app, by group. An app is deployed once `chart/values.yaml` lists it with
  `deploy: true`.
- `chart/`: the app-of-apps chart, see [`chart/README.md`](chart/README.md).
- `talos/`: node configs and the bootstrap runbook, see [`talos/README.md`](talos/README.md).
- `terraform/`: Cloudflare DNS of `davydehaas.dev`, see [`terraform/README.md`](terraform/README.md).
- `.devcontainer/`: the CLIs from `mise.toml`, see [`.devcontainer/README.md`](.devcontainer/README.md).
- `docs/`: manuals of the smart meter and water meter gateways.

## Secrets

Commit secrets only as SealedSecrets. Seal from stdin, so no plaintext file is written:

```shell
kubectl create secret generic <name> -n <namespace> --from-literal=<key>="$value" --dry-run=client -o yaml \
  | kubeseal --controller-namespace kube-system --controller-name sealed-secrets-controller --format yaml \
  > kubernetes/<group>/<app>/templates/<name>.yaml
```

Read `value` with `read -rs value`, so it stays out of the shell history.

## Hardware

|         | Home server (`yggdrasil`)        | 4x Turing RK1 (Turing Pi 2)         |
|---------|----------------------------------|-------------------------------------|
| CPU     | Intel i5 10600K (6 cores, amd64) | Rockchip RK3588 (8 cores, arm64)    |
| RAM     | 2x 16 GB DDR4                    | 16 GB LPDDR4                        |
| Storage | 3x 4 TB HDD (RAID), 16 TB HDD    | eMMC; the NVMe SSD is not usable yet |
| OS      | Ubuntu Server                    | Talos                               |
