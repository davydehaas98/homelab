# Homelab

Run these steps from the [dev container](../.devcontainer/README.md), which has `talosctl`, `kubectl`
and `tpi`. Keep `talosctl` in `mise.toml` equal to the Talos version on the nodes: its default
Kubernetes version follows its own version. Renovate bumps it, so upgrade the nodes along with it.

## Client configs and backups

`talosctl` and `kubectl` use their default configs, `~/.talos/config` and `~/.kube/config`, which
stay outside the repo. Do not set `TALOSCONFIG` to a file in the repo.

`backup-configs.sh` uploads the talosconfig, the kubeconfig, `gen/secrets.yaml` (the cluster
secrets, needed to regenerate any node or client config) and the sealed-secrets keys to 1Password
as the `yggdrasil *` documents. Its header has the restore commands. `op` needs the 1Password
desktop app, so run it on the host, not in the dev container (which only mounts the configs):

```shell
sh backup-configs.sh -c yggdrasil
```

Run it again after the client certificates are renewed, after the sealed-secrets controller adds a
key (by default every 30 days), and after regenerating the cluster secrets.

## Create Talos images

Each board has its own directory with that board's schematic and node patches (`rk1/` for Turing
RK1 nodes, `rpi4/` for Raspberry Pi 4 nodes). `gen-image.sh` picks the board with `-b`:

```shell
sh gen-image.sh -b rk1 -n jotunheim_0 -v v1.14.2
sh gen-image.sh -b rk1 -n jotunheim_1 -v v1.14.2
sh gen-image.sh -b rk1 -n jotunheim_2 -v v1.14.2
sh gen-image.sh -b rk1 -n jotunheim_3 -v v1.14.2
```

To add a Raspberry Pi 4 worker (`vanaheim_0`):

```shell
sh gen-image.sh -b rpi4 -n vanaheim_0 -v v1.14.2
```

## Flash Talos image to nodes

`rk1/flash.sh` wraps `tpi flash`/`tpi power on` for a node's slot. Pass `TPI_USER`/`TPI_PASS` to
authenticate non-interactively (BMC firmware 2.0.0+ requires authentication for every command):

```shell
export TPI_HOST=turingpi
export TPI_USER=root
export TPI_PASS=turing

sh rk1/flash.sh jotunheim_0 1
sh rk1/flash.sh jotunheim_1 2
sh rk1/flash.sh jotunheim_2 3
sh rk1/flash.sh jotunheim_3 4
```

A Raspberry Pi has no BMC. Write its image to an SD card or USB SSD instead (check the device with
`diskutil list`, then `diskutil unmountDisk /dev/diskN`) and boot the Pi from it:

```shell
sudo dd if=gen/vanaheim_0.metal-arm64.raw of=/dev/rdiskN bs=4m status=progress
```

Then run `talosctl get links --insecure -n <pi-ip>` to confirm the interface name (`end0` or
`eth0`) matches `rpi4/nodes/vanaheim_0.yaml` before applying the config.

## Talosctl

For more information, See: <https://docs.siderolabs.com/talos/latest/getting-started/getting-started>.

Install Talosctl:

```shell
curl -sL 'https://www.talos.dev/install' | bash
```

Generate talosconfig with secrets (`gen-talosconfig.sh` generates cluster secrets, if not already
present, then the talosconfig (`gen/talosconfig`), merges it into your local talosctl config
(`~/.talos/config`), and points the endpoint
at a real node since the control plane VIP only comes alive after bootstrap succeeds).

Secrets generation should only happen once — you can reuse them to generate configs for different
systems if desired:

The control plane endpoint (and so the VIP) is defined once, in `patches/cluster.yaml`; the scripts
read it from there:

```shell
export CLUSTER_NAME="yggdrasil"

sh gen-talosconfig.sh -c ${CLUSTER_NAME} -n jotunheim_0
```

Generate and apply each node's config (`apply-config.sh` wraps `gen-config.sh` and the
`talosctl apply-config` call). Pass `-b` with the node's board directory (e.g. `rk1`) so
`gen-config.sh` picks up that board's node patch. It applies with your authenticated talosconfig
first, and automatically retries with `--insecure` if the node is still in maintenance mode (no
cert trust yet):

```shell
export BOARD="rk1"

# Control plane nodes
sh apply-config.sh -b ${BOARD} -c ${CLUSTER_NAME} -n jotunheim_0 -t controlplane
sh apply-config.sh -b ${BOARD} -c ${CLUSTER_NAME} -n jotunheim_1 -t controlplane
sh apply-config.sh -b ${BOARD} -c ${CLUSTER_NAME} -n jotunheim_2 -t controlplane

# Worker node
sh apply-config.sh -b ${BOARD} -c ${CLUSTER_NAME} -n jotunheim_3 -t worker

# Raspberry Pi 4 worker (different board directory)
sh apply-config.sh -b rpi4 -c ${CLUSTER_NAME} -n vanaheim_0 -t worker
```

Bootstrap the Kubernetes cluster. This will:

- Initializes etcd cluster
- Starts Kubernetes control plane components

```shell
talosctl bootstrap --nodes jotunheim_0
```

Once bootstrap succeeds and the control plane VIP is live, you can switch the endpoint back to
it for cluster-wide access. Set the default `nodes` too, so later commands don't need `--nodes`
spelled out each time:

```shell
talosctl config endpoint $(sed -n 's|^endpoint: https://\(.*\):6443|\1|p' patches/cluster.yaml)
talosctl config nodes jotunheim_0 jotunheim_1 jotunheim_2 jotunheim_3
```

Download client configuration (`kubeconfig` requires exactly one node, so override the default
node set):

```shell
talosctl kubeconfig --nodes jotunheim_0
```

Check connection to Kubernetes and see your nodes

```shell
kubectl get nodes -o wide
```

Explore your cluster

```shell
# Health
talosctl health

# Dashboard
talosctl dashboard
```

## Upgrade Talos

Upgrade one node at a time (control plane first, then the worker), and wait until it is healthy
before starting the next.

```shell
export TALOS_VERSION="v1.14.2"

sh upgrade-talos.sh -b ${BOARD} -n jotunheim_0 -v ${TALOS_VERSION}

# Verify before the next node
talosctl --nodes jotunheim_0 etcd members
kubectl get nodes

sh upgrade-talos.sh -b ${BOARD} -n jotunheim_1 -v ${TALOS_VERSION}
sh upgrade-talos.sh -b ${BOARD} -n jotunheim_2 -v ${TALOS_VERSION}
sh upgrade-talos.sh -b ${BOARD} -n jotunheim_3 -v ${TALOS_VERSION}
```

## Install Helm charts

### Cilium CNI

<https://docs.siderolabs.com/kubernetes-guides/cni/deploying-cilium>

```shell
helm repo add cilium https://helm.cilium.io/
helm repo update

helm install cilium cilium/cilium \
    --version 1.19.9 \
    --namespace kube-system \
    --set ipam.mode=kubernetes \
    --set kubeProxyReplacement=true \
    --set securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
    --set securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
    --set cgroup.autoMount.enabled=false \
    --set cgroup.hostRoot=/sys/fs/cgroup \
    --set k8sServiceHost=localhost \
    --set k8sServicePort=7445
```

```shell
helm repo add sealed-secrets https://bitnami.github.io/sealed-secrets
helm repo update

helm install sealed-secrets sealed-secrets/sealed-secrets \
  --version 2.20.0 \
  --namespace kube-system \
  --set-string fullnameOverride=sealed-secrets-controller
```

### Sealed-secrets keys (back up and restore)

Every SealedSecret in this repo (including `homelab-repo-ssh-key`, the GitHub SSH key Argo CD uses) is
encrypted with the controller's private key. If the cluster is rebuilt and the controller generates
a new key, none of them decrypt and everything would need re-sealing. Keep a backup of the keys and
restore it **right after installing sealed-secrets, before Argo CD**.

`backup-configs.sh` backs them up to the `yggdrasil sealed-secrets keys` document in 1Password, see
[Client configs and backups](#client-configs-and-backups).

Restore (the controller keeps every key it finds and tries each one when decrypting):

```shell
op document get "yggdrasil sealed-secrets keys" | kubectl apply -f -
kubectl -n kube-system rollout restart deploy/sealed-secrets-controller
kubectl -n kube-system logs deploy/sealed-secrets-controller | grep "registered private key"
```

The log must list every restored key. Do not apply a key file that prints
`tls: private key does not match public key`; that key is unusable. A newly generated key is
fine to keep alongside the old ones, but back it up again if you seal anything with it.

## Install ArgoCD

Argo CD is installed with Helm once. After that it manages itself (the `argocd` Application in
`chart/values.yaml`) and every other app under `kubernetes/`. Requires Cilium and sealed-secrets
from above (the repo credentials in `kubernetes/core/argocd/templates/homelab-repo-ssh-key.yaml` are a
SealedSecret; re-seal it if the controller's key is new, see `kubernetes/core/argocd/README.md`).

```shell
ARGOCD_HELM_VERSION=9.7.1
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Bootstrap install with chart defaults. The repo's values (HTTPRoute, ServiceMonitors) need CRDs
# that do not exist yet, and Argo CD applies them itself once it takes over.
helm install argocd argo/argo-cd \
    --version ${ARGOCD_HELM_VERSION} \
    -n argocd --create-namespace --wait

# Hand over to GitOps: the AppProjects and the root `applications` Application. The root app then
# creates every Application (including `argocd`, which adopts the Helm release above).
helm dependency update kubernetes/core/argocd
helm template argocd kubernetes/core/argocd -n argocd \
    -s templates/project-always-sync.yaml \
    -s templates/project-no-sync.yaml \
    -s templates/applications.yaml | kubectl apply -f -
```

Apps that depend on CRDs from other apps (SealedSecret, HTTPRoute, ServiceMonitor) can fail their
first sync. Automated sync does not retry a failed commit, so re-sync them from the UI/CLI once
`sealed-secrets`, `envoy-gateway` and `prometheus-crd` are healthy.

Connect to ArgoCD UI by port forwarding the service port
(http://127.0.0.1:8080)

```shell
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
kubectl port-forward service/argocd-server -n argocd 8080:443
```

```shell
talosctl -n $NODE_IP dashboard
talosctl -n $NODE_IP kubeconfig
```
