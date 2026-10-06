FROM debian:trixie-20261005-slim

# kubectl, helm, talosctl for interacting with the cluster; jq/yq for the talos/ scripts;
# kubeseal for sealing secrets. Keep these in step with the cluster: talosctl generates machine
# configs, and its default Kubernetes version follows its own version.
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl jq && rm -rf /var/lib/apt/lists/*

ARG KUBECTL_VERSION=1.37.1
ARG KUBESEAL_VERSION=0.40.0
ARG TALOSCTL_VERSION=1.14.2

RUN ARCH=$(dpkg --print-architecture) \
    && curl -fsSL "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl" -o /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl \
    && curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash \
    && curl -fsSL "https://github.com/siderolabs/talos/releases/download/v${TALOSCTL_VERSION}/talosctl-linux-${ARCH}" -o /usr/local/bin/talosctl \
    && chmod +x /usr/local/bin/talosctl \
    && curl -fsSL "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${ARCH}" -o /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq \
    && curl -fsSL "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/kubeseal-${KUBESEAL_VERSION}-linux-${ARCH}.tar.gz" -o /tmp/kubeseal.tar.gz \
    && tar -xzf /tmp/kubeseal.tar.gz -C /usr/local/bin kubeseal \
    && rm /tmp/kubeseal.tar.gz
