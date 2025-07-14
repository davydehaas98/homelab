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
root:turing
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
Install Talosctl
```shell
curl -sL 'https://www.talos.dev/install' | bash
```

Create talosconfig secrets
```shell
export CLUSTER_IP="jotunheim_0"
export CLUSTER_ENDPOINT="https://${CLUSTER_IP}:6443"
export CLUSTER_NAME="test"

# Talosconfig
touch gen
talosctl gen secrets -o gen/secrets.yaml

talosctl gen config \
    ${CLUSTER_NAME} ${CLUSTER_ENDPOINT} \
    --output-types talosconfig \
    --output talosconfig \
    --with-secrets gen/secrets.yaml \
    --force

talosctl config merge talosconfig

talosctl config endpoint jotunheim_0
```

Generate config
```shell
export NODE_NAME="jotunheim_2"
export NODE_TYPE="controlplane" # controlplane | worker
export KUBERNETES_VERSION="1.33.2"

talosctl gen config \
    ${CLUSTER_NAME} ${CLUSTER_ENDPOINT} \
    --output-types ${NODE_TYPE} \
    --output gen/${NODE_NAME}.yaml \
    --with-cluster-discovery=false \
    --with-secrets gen/secrets.yaml \
    --config-patch @nodes/${NODE_NAME}.yaml \
    --config-patch @patches/cluster.yaml \
    --kubernetes-version ${KUBERNETES_VERSION} \
    --force
```

Apply config to node
```shell
export NODE_NAME="jotunheim_3"

talosctl apply-config \
        --nodes ${NODE_NAME} \
        --file gen/${NODE_NAME}.yaml \
        --insecure \
        --mode reboot

```

Initialize etcd database
```shell
talosctl bootstrap -e jotunheim_0 --nodes jotunheim_0
```
```shell
talosctl kubeconfig -e jotunheim_0 --nodes jotunheim_0
```

## Install Helm charts

```shell
helm repo add cilium https://helm.cilium.io/
helm repo update
helm install cilium cilium/cilium \
    --version 1.16.3 \
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
ARGOCD_HELM_VERSION=7.4.4
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm install argocd argo/argo-cd \
    --version ${ARGOCD_HELM_VERSION} \
    -n argocd --create-namespace
```

```shell
kubectl config set-context --current --namespace=argocd
argocd login --core
argocd proj create no-sync --dest '*,*' --src '*' --allow-cluster-resource '*/*'
argocd app create argocd \
    --repo https://github.com/davydehaas98/homelab.git --path applications \
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
