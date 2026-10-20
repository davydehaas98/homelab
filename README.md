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
- `docs/`: Mermaid diagrams ([`docs/diagrams/`](docs/diagrams/README.md)) and manuals of the smart meter and water meter gateways.

## Secrets

Commit secrets only as SealedSecrets. `scripts/seal-secret.sh` asks for the values without echo, so no plaintext is
written or kept in the shell history, and `-m` adds a key to an existing Secret:

```shell
sh scripts/seal-secret.sh -n <name> -N <namespace> -a <group>/<app> -k <key>
```

## Hardware

|         | Home server (`yggdrasil`)        | 4x Turing RK1 (Turing Pi 2)         |
|---------|----------------------------------|-------------------------------------|
| CPU     | Intel i5 10600K (6 cores, amd64) | Rockchip RK3588 (8 cores, arm64)    |
| RAM     | 2x 16 GB DDR4                    | 16 GB LPDDR4                        |
| Storage | 3x 4 TB HDD (RAID), 16 TB HDD    | eMMC; the NVMe SSD is not usable yet |
| OS      | Ubuntu Server                    | Talos                               |
