# Homelab Infrastructure

This repository manages a homelab infrastructure using a multi-layered approach to provide a robust and scalable environment for various services.

## Project Overview

The infrastructure is organized into three primary layers:

- **Infrastructure Layer**: Provides the base OS and networking. It utilizes **Talos OS** for ARM-based nodes and **Ubuntu** for x86 nodes.
- **Orchestration Layer**: Manages the container lifecycle using a **Kubernetes** cluster with **Cilium** as the CNI and **Argo CD** for declarative deployments.
- **Application Layer**: A suite of managed services (media, storage, monitoring, etc.) packaged as **Helm** charts and managed via the `applications/` directory.

## Directory Structure

- `talos/`: Talos OS bootstrap runbook ([`talos/README.md`](talos/README.md)), config generation scripts, and per-board node patches (`rk1/`, `rpi4/`).
- `applications/`: One wrapper Helm chart per service, organized by group (`core`, `devices`, `home`, `media`, `monitoring`, `other`, `storage`). `_base/` is the scaffold for new apps.
- `chart/`: The app-of-apps Helm chart that renders an Argo CD `Application` for every entry in `chart/values.yaml` with `deploy: true`.
- `disabled/`: Manifests intentionally kept out of the sync path.
- `scripts/`: Utility scripts for manual operations, such as node preparation and status checks.
- `docs/`: Reference manuals for home hardware (smart meter and water meter gateways).

## Deployment

Argo CD syncs everything under `applications/` from `main`, so a merge to `main` is a deployment. An app directory is only deployed once it is listed in `chart/values.yaml`. Secrets are committed only as Bitnami SealedSecrets; see [`applications/core/argocd/README.md`](applications/core/argocd/README.md). Contributor and agent guidance lives in [`AGENTS.md`](AGENTS.md).

## Hardware Specification

- **Yggdrasil**
  - **CPU:** Intel i5 10600K (6 cores, AMD64)
  - **RAM:** 2x 16GB DDR4 @ 3.200MT/s
  - **Storage:** 3x Seagate IronWolf 4TB HDD
  - **OS:** Ubuntu Server 26.10

- **4x Turing RK1 CM (Turing Pi 2.0)**
  - **CPU:** Rockchip RK3588 SoC (8 cores, ARM)
  - **RAM:** 16GB LPDDR4
  - **Storage:** WD Blue SN580 1TB M.2 SSD
  - **OS:** Talos OS v1.14.2
