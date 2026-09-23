# Homelab

## Install TPI

```shell
curl https://sh.rustup.rs -sSf | sh
```

You might need to reboot.

```shell
cargo install tpi
```

## Create Talos images

RK1 (Turing Pi 2) node scripts live under `rk1/`:

```shell
sh rk1/gen-image.sh jotunheim_0
sh rk1/gen-image.sh jotunheim_1
sh rk1/gen-image.sh jotunheim_2
sh rk1/gen-image.sh jotunheim_3
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

## Talosctl

For more information, See: <https://docs.siderolabs.com/talos/latest/getting-started/getting-started>.

Install Talosctl:

```shell
curl -sL 'https://www.talos.dev/install' | bash
```

Generate talosconfig with secrets (`gen-talosconfig.sh` generates cluster secrets, if not already
present, then the talosconfig, merges it into your local talosctl config, and points the endpoint
at a real node since the control plane VIP only comes alive after bootstrap succeeds).

Secrets generation should only happen once — you can reuse them to generate configs for different
systems if desired:

```shell
export CLUSTER_IP="192.168.1.55"
export CLUSTER_NAME="test"

sh gen-talosconfig.sh -c ${CLUSTER_NAME} -i ${CLUSTER_IP} -n jotunheim_0
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
talosctl config endpoint $CLUSTER_IP
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

## Install Helm charts

```shell
CILIUM_VERSION=1.19.8
helm repo add cilium https://helm.cilium.io/
helm repo update
helm install cilium cilium/cilium \
    --version ${CILIUM_VERSION} \
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
SEALED_SECRETS_VERSION=2.18.6
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm repo update
helm install sealed-secrets sealed-secrets/sealed-secrets \
  --version ${SEALED_SECRETS_VERSION} \
  --namespace kube-system \
  --set-string fullnameOverride=sealed-secrets-controller
```

## Install ArgoCD

```shell
ARGOCD_HELM_VERSION=9.4.18
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm install argocd argo/argo-cd \
    --version ${ARGOCD_HELM_VERSION} \
    -n argocd --create-namespace
```

Connect to ArgoCD UI by port forwarding the service port
(http://127.0.0.1:8080)

```shell
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
kubectl port-forward service/argocd-server -n argocd 8080:443
```

```shell
kubectl config set-context --current --namespace=argocd
argocd login --core
argocd proj create always-sync --dest '*,*' --src '*' --allow-cluster-resource '*/*'
argocd proj create no-sync --dest '*,*' --src '*' --allow-cluster-resource '*/*'
argocd app create argocd \
    --repo https://github.com/davydehaas98/homelab.git --path applications/core/argocd \
    --dest-server https://kubernetes.default.svc --dest-namespace argocd \
    --directory-recurse

argocd app sync argocd
argocd app sync metallb \
  ingress-nginx \
  sealed-secrets \
  external-dns \
  cert-manager
```

```shell
talosctl -n $NODE_IP dashboard
talosctl -n $NODE_IP kubeconfig
```
