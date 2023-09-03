- [Setup nodes](#setup-nodes)
  - [Install general dependencies](#install-general-dependencies)
  - [Enable iptables bridged traffic on the node](#enable-iptables-bridged-traffic-on-the-node)
  - [Ensure swap is disabled](#ensure-swap-is-disabled)
  - [Install containerd](#install-containerd)
  - [Install runc](#install-runc)
  - [Install CNI (Container Network Interface) network plugins](#install-cni-container-network-interface-network-plugins)
  - [Install kubeadm, kubelet \& kubectl](#install-kubeadm-kubelet--kubectl)
- [Configure Kubernetes Control Plane](#configure-kubernetes-control-plane)
  - [Create cluster using kubeadm](#create-cluster-using-kubeadm)
  - [OPTIONAL - Untaint node to allow master node to accept pods](#optional---untaint-node-to-allow-master-node-to-accept-pods)
  - [Install Helm](#install-helm)
  - [Install CNI (Container Network Interface) plugin (Cilium)](#install-cni-container-network-interface-plugin-cilium)
  - [OPTIONAL - Install Cilium CLI](#optional---install-cilium-cli)
  - [Install Prometheus CRD](#install-prometheus-crd)
- [Configure worker node](#configure-worker-node)
- [Setup Argo CD](#setup-argo-cd)
  - [Install Argo CD](#install-argo-cd)
  - [Install Argo CD CLI](#install-argo-cd-cli)
  - [Setup ArgoCD](#setup-argocd)
- [Install Kubeseal](#install-kubeseal)
- [Upgrade Kubernetes cluster](#upgrade-kubernetes-cluster)
  - [Upgrade control plane nodes](#upgrade-control-plane-nodes)
  - [Upgrade worker nodes](#upgrade-worker-nodes)


# Setup nodes
## Install general dependencies
```
sudo apt-get update
sudo apt-get install -y apt-transport-https curl
```

## Enable iptables bridged traffic on the node
```
echo "fs.inotify.max_user_instances=512" | sudo tee -a /etc/sysctl.conf
echo "fs.inotify.max_user_watches=204800" | sudo tee -a /etc/sysctl.conf

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
```

## Ensure swap is disabled
```
sudo swapoff -a
sudo sed -i -e '/swap/d' /etc/fstab
```

## Install containerd
```
CONTAINERD_VERSION=1.7.2
PROCESSOR_ARCH=$(dpkg --print-architecture)

sudo mkdir /etc/containerd
cat <<EOF | sudo tee /etc/containerd/config.toml
version = 2
[plugins]
  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
    runtime_type = "io.containerd.runc.v2"
    [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
      SystemdCgroup = true
EOF

curl -fsSLo containerd-${CONTAINERD_VERSION}-linux-${PROCESSOR_ARCH}.tar.gz \
  https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-${PROCESSOR_ARCH}.tar.gz

sudo tar Cxzvf /usr/local containerd-${CONTAINERD_VERSION}-linux-${PROCESSOR_ARCH}.tar.gz
sudo rm containerd-${CONTAINERD_VERSION}-linux-${PROCESSOR_ARCH}.tar.gz

sudo curl -fsSLo /etc/systemd/system/containerd.service \
  https://raw.githubusercontent.com/containerd/containerd/main/containerd.service

sudo systemctl daemon-reload
sudo systemctl enable --now containerd
```

## Install runc
```
RUNC_VERSION=1.1.7
PROCESSOR_ARCH=$(dpkg --print-architecture)

curl -fsSLo runc.${PROCESSOR_ARCH} \
  https://github.com/opencontainers/runc/releases/download/v${RUNC_VERSION}/runc.${PROCESSOR_ARCH}

sudo install -m 755 runc.${PROCESSOR_ARCH} /usr/local/sbin/runc
rm runc.${PROCESSOR_ARCH}
```

## Install CNI (Container Network Interface) network plugins
```
CNI_VERSION=1.3.0
PROCESSOR_ARCH=$(dpkg --print-architecture)

curl -fsSLo cni-plugins-linux-${PROCESSOR_ARCH}-v${CNI_VERSION}.tgz \
  https://github.com/containernetworking/plugins/releases/download/v${CNI_VERSION}/cni-plugins-linux-${PROCESSOR_ARCH}-v${CNI_VERSION}.tgz

sudo mkdir -p /opt/cni/bin
sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-${PROCESSOR_ARCH}-v${CNI_VERSION}.tgz

sudo rm cni-plugins-linux-${PROCESSOR_ARCH}-v${CNI_VERSION}.tgz
```

## Install kubeadm, kubelet & kubectl
```
KUBERNETES_VERSION=1.28.1
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg \
  https://dl.k8s.io/apt/doc/apt-key.gpg

echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet=${KUBERNETES_VERSION}-00 kubeadm=${KUBERNETES_VERSION}-00 kubectl=${KUBERNETES_VERSION}-00
sudo apt-mark hold kubelet kubeadm kubectl
```

---

# Configure Kubernetes Control Plane
Configure the control plane on the master node only.
## Create cluster using kubeadm
```
sudo kubeadm init --config config.yaml --upload-certs

sudo mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

## OPTIONAL - Untaint node to allow master node to accept pods
```
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```

## Install Helm
```
HELM_VERSION=3.12.2
PROCESSOR_ARCH=$(dpkg --print-architecture)

curl -fsSLo helm-v${HELM_VERSION}-linux-${PROCESSOR_ARCH}.tar.gz \
  https://get.helm.sh/helm-v${HELM_VERSION}-linux-${PROCESSOR_ARCH}.tar.gz
sudo tar xzvf helm-v${HELM_VERSION}-linux-${PROCESSOR_ARCH}.tar.gz linux-${PROCESSOR_ARCH}/helm
sudo mv linux-${PROCESSOR_ARCH}/helm /usr/local/bin/
sudo rm linux-${PROCESSOR_ARCH} -r
sudo rm helm-v${HELM_VERSION}-linux-${PROCESSOR_ARCH}.tar.gz
```

## Install CNI (Container Network Interface) plugin (Cilium)
```
API_SERVER_IP=cloud.davydehaas.dev
API_SERVER_PORT=6443
CILIUM_HELM_VERSION=1.14.1

helm repo add cilium https://helm.cilium.io/
helm repo update
helm install cilium cilium/cilium \
    --version ${CILIUM_HELM_VERSION} \
    --namespace kube-system \
	--set operator.replicas=1 \
    --set kubeProxyReplacement=strict \
    --set k8sServiceHost=${API_SERVER_IP} \
    --set k8sServicePort=${API_SERVER_PORT}
```

## OPTIONAL - Install Cilium CLI
```
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=$(dpkg --print-architecture)

if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
```

## Install Prometheus CRD
```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus-crds prometheus-community/prometheus-operator-crds
```

---
# Configure worker node
Generate kubeadm join command to use on worker node.
```
kubeadm token create --print-join-command
```
---

# Setup Argo CD

## Install Argo CD
```
ARGOCD_HELM_VERSION=5.45.0
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm install argocd argo/argo-cd --version ${ARGOCD_HELM_VERSION} \
    --namespace argocd --create-namespace
```

## Install Argo CD CLI
```
ARGOCD_CLI_VERSION=v2.8.2
PROCESSOR_ARCH=$(dpkg --print-architecture)

curl -sSL -o argocd-linux-${PROCESSOR_ARCH} https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_CLI_VERSION}/argocd-linux-${PROCESSOR_ARCH}
sudo install -m 555 argocd-linux-${PROCESSOR_ARCH} /usr/local/bin/argocd
rm argocd-linux-${PROCESSOR_ARCH}
```

```
kubectl config set-context --current --namespace=argocd
argocd proj create
argocd app create argocd \
    --repo https://github.com/davydehaas98/gitops.git --path core \
    --dest-server https://kubernetes.default.svc --dest-namespace argocd
argocd app sync argocd
argocd app sync ingress-nginx \
    metallb \
    cert-manager \
    sealed-secrets
```

Set cloudflare-api-token sealed secret.

```
argocd app sync external-dns
```

## Setup ArgoCD
```
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
kubectl get svc argocd-server -n argocd
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```
Log in to ArgoCD.

---

# Install Kubeseal
> Kubeseal makes it possible to store secrets encrypted on Git that only the cluster itself can decrypt.

Install Kubeseal on a node to encrypt secrets:
```
KUBESEAL_VERSION=0.22.0
PROCESSOR_ARCH=$(dpkg --print-architecture)

wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/kubeseal-${KUBESEAL_VERSION}-linux-${PROCESSOR_ARCH}.tar.gz
tar -xvzf kubeseal-${KUBESEAL_VERSION}-linux-${PROCESSOR_ARCH}.tar.gz kubeseal
rm kubeseal-${KUBESEAL_VERSION}-linux-${PROCESSOR_ARCH}.tar.gz

sudo install -m 755 kubeseal /usr/local/bin/kubeseal
```
Create secret.yaml:
```
apiVersion: v1
kind: Secret
metadata:
  name: database-credentials
  namespace: default
type: Opaque
stringData:
  username: admin
  password: p4ssw0rd
```
Convert secret.yaml to sealed-secret.yaml:
```
cat secret.yaml | kubeseal --controller-namespace sealed-secrets --controller-name sealed-secrets-controller --format yaml > sealed-secret.yaml
```

---

# Upgrade Kubernetes cluster
Find the Kubernetes version in the apt-cache madison list you want to upgrade to.)
```
sudo apt update
sudo apt-cache madison kubeadm | tac
```

## Upgrade control plane nodes
Install kubeadm:
```
KUBERNETES_VERSION=1.28.1
sudo apt update
sudo apt-mark unhold kubeadm kubectl kubelet
sudo apt-get install -y kubeadm=${KUBERNETES_VERSION}-00 kubelet=${KUBERNETES_VERSION}-00 kubectl=${KUBERNETES_VERSION}-00
sudo apt-mark hold kubeadm kubectl kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet
```
## Upgrade worker nodes
```
KUBERNETES_VERSION=1.28.1
NODE_NAME=instance-20230720-1942

kubectl cordon ${NODE_NAME}
kubectl drain ${NODE_NAME} --ignore-daemonsets --delete-emptydir-data
sudo apt update
sudo apt-mark unhold kubeadm kubectl kubelet
sudo apt-get install -y kubeadm=${KUBERNETES_VERSION}-00 kubelet=${KUBERNETES_VERSION}-00 kubectl=${KUBERNETES_VERSION}-00
sudo apt-mark hold kubeadm kubectl kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet
kubectl uncordon ${NODE_NAME}
```
