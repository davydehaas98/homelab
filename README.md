# Homelab

Kubernetes cluster `yggdrasil` on Talos, with Cilium and Argo CD. Argo CD deploys `kubernetes/` from `main`.
Agent guidance is in [`AGENTS.md`](AGENTS.md).

## Layout

- `kubernetes/`: one Helm chart per app, by group, deployed by an ApplicationSet once its `argocd.yaml` has
  `deploy: true`, see [`kubernetes/README.md`](kubernetes/README.md).
- `talos/`: node configs and the bootstrap runbook, see [`talos/README.md`](talos/README.md).
- `terraform/`: Cloudflare DNS and the arr settings (devopsarr), see [`terraform/README.md`](terraform/README.md).
- `.devcontainer/`: the CLIs from `mise.toml`, see [`.devcontainer/README.md`](.devcontainer/README.md).
- `docs/`: Mermaid diagrams ([`docs/diagrams/`](docs/diagrams/README.md)) and manuals of the smart meter and water meter gateways.

## Apps

The apps with `deploy: true` in their `argocd.yaml`, as `kubernetes/<group>/<app>`.

### core

| App                       | Description                      |
| ------------------------- | -------------------------------- |
| argocd                    | GitOps controller                |
| cert-manager              | TLS certificates                 |
| cilium                    | CNI, Hubble                      |
| descheduler               | Evicts misplaced pods            |
| envoy-gateway             | Gateway API ingress              |
| intel-gpu-resource-driver | Intel GPU access                 |
| kubernetes-replicator     | Copies Secrets across namespaces |
| metrics-server            | Resource metrics                 |
| node-feature-discovery    | Node labels from hardware        |
| sealed-secrets            | Encrypted Secrets in git         |
| talos-backup              | etcd snapshots                   |
| tuppr                     | Talos and Kubernetes upgrades    |
| vpa                       | Resource recommendations         |

### games

| App       | Description |
| --------- | ----------- |
| factorio  | Game server |
| minecraft | Game server |

### home

| App              | Description     |
| ---------------- | --------------- |
| actual-budget    | Budgeting       |
| airtrail         | Flight log      |
| home-assistant   | Home automation |
| immich           | Photos          |
| memos            | Notes           |
| mosquitto        | MQTT broker     |
| nextcloud        | Files and sync  |
| personal-website | Website         |
| zigbee2mqtt      | Zigbee bridge   |

### media-server

| App           | Description                  |
| ------------- | ---------------------------- |
| bazarr        | Subtitles                    |
| dispatcharr   | IPTV tuner                   |
| jellyfin      | Media server                 |
| lazylibrarian | Books                        |
| lidarr        | Music                        |
| media-server  | Namespace and shared volumes |
| plex          | Media server                 |
| prowlarr      | Indexers                     |
| radarr        | Movies                       |
| sabnzbd       | Usenet downloader            |
| seerr         | Requests                     |
| sonarr        | Series                       |
| tautulli      | Plex monitoring              |
| tracearr      | Playback monitoring          |

### monitoring

| App                   | Description                 |
| --------------------- | --------------------------- |
| fluent-bit            | Log shipper                 |
| grafana               | Dashboards                  |
| grafana-dashboards    | Dashboards as ConfigMaps    |
| grafana-mcp           | Grafana MCP server          |
| loki                  | Log storage                 |
| node-problem-detector | Kernel and hardware reports |
| prometheus            | Metrics and alerts          |
| prometheus-crd        | Prometheus Operator CRDs    |

### security

| App             | Description              |
| --------------- | ------------------------ |
| authentik       | Identity provider (OIDC) |
| kyverno         | Policy engine            |
| policy-reporter | Policy report UI         |
| trivy-operator  | Vulnerability scans      |

### storage

| App                 | Description                        |
| ------------------- | ---------------------------------- |
| cloudnative-pg      | PostgreSQL operator and backups    |
| seaweedfs           | S3 storage                         |
| snapshot-controller | Volume snapshots                   |
| velero              | Backups of resources and volumes   |
| zfs-localpv         | ZFS volumes (default StorageClass) |

### tools

| App          | Description          |
| ------------ | -------------------- |
| adguard-home | DNS filtering        |
| gatus        | Status page          |
| headlamp     | Kubernetes dashboard |
| homepage     | Start page           |
| it-tools     | Developer utilities  |
| omni-tools   | Everyday utilities   |

## Hardware

|         | Storage node (`midgard-0`)              | 4x Turing RK1 (Turing Pi 2)      |
| ------- | --------------------------------------- | -------------------------------- |
| CPU     | Intel i5 10600K (6 cores, amd64)        | Rockchip RK3588 (8 cores, arm64) |
| RAM     | 2x 16 GB DDR4                           | 16 GB LPDDR4                     |
| Storage | 128 GB SSD, 500 GB NVMe, 3x 4 TB, 16 TB | eMMC                             |
| OS      | Talos                                   | Talos                            |
