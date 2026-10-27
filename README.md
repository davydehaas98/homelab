# Homelab

Kubernetes cluster `yggdrasil` on Talos, with Cilium and Argo CD. Argo CD deploys `kubernetes/` from `main`.
Agent guidance is in [`AGENTS.md`](AGENTS.md).

## Layout

- `kubernetes/`: one Helm chart per app, by group, deployed by an ApplicationSet once its `argocd.yaml` has
  `deploy: true`, see [`kubernetes/README.md`](kubernetes/README.md).
- `talos/`: node configs and the bootstrap runbook, see [`talos/README.md`](talos/README.md).
- `terraform/`: Cloudflare DNS of `davydehaas.dev`, see [`terraform/README.md`](terraform/README.md).
- `.devcontainer/`: the CLIs from `mise.toml`, see [`.devcontainer/README.md`](.devcontainer/README.md).
- `docs/`: Mermaid diagrams ([`docs/diagrams/`](docs/diagrams/README.md)) and manuals of the smart meter and water meter gateways.

## Apps

The apps with `deploy: true` in their `argocd.yaml`, as `kubernetes/<group>/<app>`.

### core

| App                    | Description               |
| ---------------------- | ------------------------- |
| argocd                 | GitOps controller         |
| cert-manager           | TLS certificates          |
| cilium                 | CNI, Hubble               |
| descheduler            | Evicts misplaced pods     |
| envoy-gateway          | Gateway API ingress       |
| metrics-server         | Resource metrics          |
| node-feature-discovery | Node labels from hardware |
| sealed-secrets         | Encrypted Secrets in git  |
| vpa                    | Resource recommendations  |

### games

| App      | Description |
| -------- | ----------- |
| factorio | Game server |

### home

| App              | Description     |
| ---------------- | --------------- |
| home-assistant   | Home automation |
| immich           | Photos          |
| nextcloud        | Files and sync  |
| personal-website | Website         |

### media-server

| App          | Description                  |
| ------------ | ---------------------------- |
| bazarr       | Subtitles                    |
| jellyfin     | Media server                 |
| lidarr       | Music                        |
| media-server | Namespace and shared volumes |
| prowlarr     | Indexers                     |
| radarr       | Movies                       |
| sabnzbd      | Usenet downloader            |
| seerr        | Requests                     |
| sonarr       | Series                       |

### monitoring

| App                | Description              |
| ------------------ | ------------------------ |
| fluent-bit         | Log shipper              |
| grafana            | Dashboards               |
| grafana-dashboards | Dashboards as ConfigMaps |
| grafana-mcp        | Grafana MCP server       |
| loki               | Log storage              |
| prometheus         | Metrics and alerts       |
| prometheus-crd     | Prometheus Operator CRDs |

### security

| App             | Description              |
| --------------- | ------------------------ |
| authentik       | Identity provider (OIDC) |
| kyverno         | Policy engine            |
| policy-reporter | Policy report UI         |

### storage

| App                             | Description                        |
| ------------------------------- | ---------------------------------- |
| cloudnative-pg                  | PostgreSQL operator                |
| democratic-csi                  | iSCSI volumes                      |
| nfs-subdir-external-provisioner | NFS volumes (default StorageClass) |
| seaweedfs                       | S3 storage                         |

### tools

| App        | Description          |
| ---------- | -------------------- |
| gatus      | Status page          |
| headlamp   | Kubernetes dashboard |
| homepage   | Start page           |
| it-tools   | Developer utilities  |
| omni-tools | Everyday utilities   |

## Hardware

|         | Home server (`yggdrasil`)        | 4x Turing RK1 (Turing Pi 2)      |
| ------- | -------------------------------- | -------------------------------- |
| CPU     | Intel i5 10600K (6 cores, amd64) | Rockchip RK3588 (8 cores, arm64) |
| RAM     | 2x 16 GB DDR4                    | 16 GB LPDDR4                     |
| Storage | 3x 4 TB HDD (RAID), 16 TB HDD    | eMMC                             |
| OS      | Ubuntu Server                    | Talos                            |
