# Homelab

## Install TPI

```shell
curl https://sh.rustup.rs -sSf | sh
cargo install tpi
```

## Create Talos images

```shell
sh image.sh jotunheim_0
sh image.sh jotunheim_1
sh image.sh jotunheim_2
sh image.sh jotunheim_3
```

## Flash Talos image to nodes

| User | Password |
| ---- | -------- |
| root | turing   |

```shell
tpi flash -i jotunheim_0.metal-arm64.raw -n 1
tpi power on -n 1

tpi flash -i jotunheim_1.metal-arm64.raw -n 2
tpi power on -n 2

tpi flash -i jotunheim_2.metal-arm64.raw -n 3
tpi power on -n 3

tpi flash -i jotunheim_3.metal-arm64.raw -n 4
tpi power on -n 4
```

## Talosctl

For more information, See: <https://docs.siderolabs.com/talos/latest/getting-started/getting-started>.

Install Talosctl:

```shell
curl -sL 'https://www.talos.dev/install' | bash
```

Generate talosconfig with secrets:

```shell
export CLUSTER_IP="192.168.1.55"
export CLUSTER_ENDPOINT="https://${CLUSTER_IP}:6443"
export CLUSTER_NAME="test"

# Generate secrets
touch gen
talosctl gen secrets -o gen/secrets.yaml

# Generate config
talosctl gen config \
    ${CLUSTER_NAME} ${CLUSTER_ENDPOINT} \
    --output-types talosconfig \
    --output talosconfig \
    --with-secrets gen/secrets.yaml \
    --force

talosctl config merge talosconfig

talosctl config endpoint $CLUSTER_IP
```

Generate node config:

```shell
export NODE_NAME="jotunheim_3"
export NODE_TYPE="worker" # controlplane | worker
export KUBERNETES_VERSION="1.33.2"

talosctl gen config \
    ${CLUSTER_NAME} ${CLUSTER_ENDPOINT} \
    --output-types ${NODE_TYPE} \
    --output gen/${NODE_NAME}.yaml \
    --with-cluster-discovery=false \
    --with-secrets gen/secrets.yaml \
    --config-patch @patches/cluster.yaml \
    --config-patch @nodes/${NODE_NAME}.yaml \
    --kubernetes-version ${KUBERNETES_VERSION} \
    --force
```

Apply node config and reboot:

```shell
export NODE_NAME="jotunheim_3"

talosctl apply-config \
    --nodes ${NODE_NAME} \
    --file gen/${NODE_NAME}.yaml \
    --mode reboot \
    --insecure
```

Bootstrap the Kubernetes cluster. This will:

- Initializes etcd cluster
- Starts Kubernetes control plane components

```shell
talosctl bootstrap --nodes jotunheim_0
```

Download client configuration:

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
talosctl health --nodes jotunheim_0

# Dashboard
talosctl dashboard --nodes jotunheim_0,jotunheim_1,jotunheim_2,jotunheim_3
```

## Install Helm charts

```shell
CILIUM_VERSION=1.18.5
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
SEALED_SECRETS_VERSION=2.16.1
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm repo update
helm install sealed-secrets sealed-secrets/sealed-secrets \
  --version ${SEALED_SECRETS_VERSION} \
  --namespace kube-system \
  --set-string fullnameOverride=sealed-secrets-controller
```

## Install ArgoCD

```shell
ARGOCD_HELM_VERSION=7.9.1
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm install argocd argo/argo-cd \
    --version ${ARGOCD_HELM_VERSION} \
    -n argocd --create-namespace
```

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
    --repo https://github.com/davydehaas98/homelab.git --path applications/_core/argocd \
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
