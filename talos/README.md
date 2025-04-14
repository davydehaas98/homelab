## Install TPI

```shell
curl https://sh.rustup.rs -sSf | sh
cargo install tpi
```

## Flash Talos image to RK1 nodes

```shell
rm metal-arm64.raw.xz
rm metal-arm64.raw
curl -LOk https://factory.talos.dev/image/eaff5a1425d525ccea8a1691d25426dc21c1b2eaab822c4cd2756ddf9f8658b0/v1.9.5/metal-arm64.raw.xz
xz -d metal-arm64.raw.xz

tpi flash -i metal-arm64.raw
```

## Format SD Card in BMC
SSH into BMC (root:turing) and create new partition via fdisk

```shell
ssh root@turingpi
fdisk /dev/mmcblk0
mkfs.ext4 /dev/mmcblk0p1
```

## Flash Talos image to RK1 nodes
Download Talos metal rk1 arm64 image
(https://github.com/nberlee/talos/releases)

```shell
cd /mnt/sdcard
rm metal-arm64.raw.xz
curl -LOk https://github.com/nberlee/talos/releases/download/v1.8.2/metal-arm64.raw.xz
# Might take a minute
xz -d metal-arm64.raw.xz

tpi flash -i metal-arm64.raw -n 1
tpi flash -i metal-arm64.raw -n 2
tpi flash -i metal-arm64.raw -n 3
tpi flash -i metal-arm64.raw -n 4
```

## Power on RK1 nodes

```shell
tpi power on -n 1
tpi power on -n 2
tpi power on -n 3
tpi power on -n 4
```

Give these nodes a couple minutes to start up so you can collect the entire uart log output in one command.

## Pull serial uart console to find each node's IP address

```shell
tpi uart -n 1 get | tee -a /mnt/sdcard/uart.1.log | grep "assigned address"
tpi uart -n 2 get | tee -a /mnt/sdcard/uart.2.log | grep "assigned address"
tpi uart -n 3 get | tee -a /mnt/sdcard/uart.3.log | grep "assigned address"
tpi uart -n 4 get | tee -a /mnt/sdcard/uart.4.log | grep "assigned address"
```

## Talosctl

```shell
curl -sL 'https://www.talos.dev/install' | bash
```

```shell
export CLUSTER_NAME="test"
export NODE_IP="192.168.2.18"
export CLUSTER_ENDPOINT="https://${NODE_IP}:6443"

# Talosconfig
touch gen
talosctl gen secrets -o gen/secrets.yaml --force
talosctl gen config \
    ${CLUSTER_NAME} ${CLUSTER_ENDPOINT} \
    --output-types talosconfig \
    --output talosconfig \
    --with-secrets gen/secrets.yaml \
    --force

talosctl config merge talosconfig
```

```shell
export NODE_IP="192.168.2.18"
./gen-config.sh -c test \
    -k 1.30.6 \
    -i ${NODE_IP} \
    -t controlplane -n 0
```

Initialize etcd database
```shell
talosctl bootstrap -e controlplane-0 --nodes controlplane-0
```
```shell
talosctl kubeconfig -e controlplane-0 --nodes controlplane-0
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
