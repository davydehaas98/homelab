# Setup
## Set environmentals and versions
```
PROCESSOR_ARCH=$(dpkg --print-architecture)
CONTAINERD_VERSION=1.7.2
RUNC_VERSION=1.1.7
CNI_VERSION=1.3.0
KUBERNETES_VERSION=1.27.3
HELM_VERSION=3.12.1
```

## Install general dependencies
```
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl git open-iscsi
```

## Install containerd
```
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

sudo curl -fsSLo /etc/systemd/system/containerd.service \
  https://raw.githubusercontent.com/containerd/containerd/main/containerd.service

sudo systemctl daemon-reload
sudo systemctl enable --now containerd
```

## Install runc
```
curl -fsSLo runc.${PROCESSOR_ARCH} \
  https://github.com/opencontainers/runc/releases/download/v${RUNC_VERSION}/runc.${PROCESSOR_ARCH}

sudo install -m 755 runc.${PROCESSOR_ARCH} /usr/local/sbin/runc
```

## Install CNI (Container Network Interface) network plugins
```
curl -fsSLo cni-plugins-linux-${PROCESSOR_ARCH}-v${CNI_VERSION}.tgz \
  https://github.com/containernetworking/plugins/releases/download/v${CNI_VERSION}/cni-plugins-linux-${PROCESSOR_ARCH}-v${CNI_VERSION}.tgz

sudo mkdir -p /opt/cni/bin
sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-${PROCESSOR_ARCH}-v${CNI_VERSION}.tgz
```

## Enable overlay and br_netfilter kernal modules, let iptables see bridged network traffic and enable IPv4 ip_forward
```
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe -a overlay br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
```

## Install kubeadm, kubelet & kubectl
```
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg \
  https://dl.k8s.io/apt/doc/apt-key.gpg

echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet=${KUBERNETES_VERSION}-00 kubeadm=${KUBERNETES_VERSION}-00 kubectl=${KUBERNETES_VERSION}-00
sudo apt-mark hold kubelet kubeadm kubectl
```

## Ensure swap is disabled
```
swapon --show
sudo swapoff -a
sudo sed -i -e '/swap/d' /etc/fstab
```

## Create cluster using kubeadm (The number of available CPUs has to be 2 or more.)
```
sudo kubeadm init --cri-socket=unix:///var/run/containerd/containerd.sock --pod-network-cidr=10.244.0.0/16
```

## Configure kubectl
```
sudo mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

## Untaint node to allow master node to accept pods
```
kubectl taint nodes --all node-role.kubernetes.io/master-
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```

## Install Helm
```
curl -fsSLo helm-v${HELM_VERSION}-linux-${PROCESSOR_ARCH}.tar.gz \
  https://get.helm.sh/helm-v${HELM_VERSION}-linux-${PROCESSOR_ARCH}.tar.gz
sudo tar xzvf helm-v${HELM_VERSION}-linux-${PROCESSOR_ARCH}.tar.gz linux-arm64/helm
sudo mv linux-${PROCESSOR_ARCH}/helm /usr/local/bin/
sudo rm linux-${PROCESSOR_ARCH} -r
```

## Install CNI (Container Network Interface) plugin (Cilium)
```
CILIUM_HELM_VERSION=1.13.4
helm repo add cilium https://helm.cilium.io/
helm repo update
helm install cilium cilium/cilium --namespace kube-system --version ${CILIUM_HELM_VERSION}
```

## Install Argo CD
```
ARGOCD_HELM_VERSION=5.36.7
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm install argocd argo/argo-cd --namespace argocd --create-namespace --version ${ARGOCD_HELM_VERSION}
```
### Setup ArgoCD
```
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
kubectl get svc argocd-server -n argocd
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```
Log in to ArgoCD


## Install Kubeseal
```
KUBESEAL_VERSION=0.22.0
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/kubeseal-${KUBESEAL_VERSION}-linux-${PROCESSOR_ARCH}.tar.gz
tar -xvzf kubeseal-${KUBESEAL_VERSION}-linux-${PROCESSOR_ARCH}.tar.gz kubeseal
sudo install -m 755 kubeseal /usr/local/bin/kubeseal
```
