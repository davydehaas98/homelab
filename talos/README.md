# Talos

Run from `talos/` in the [dev container](../.devcontainer/README.md). Keep `talosctl` in `mise.toml` equal to the
Talos version on the nodes, as its default Kubernetes version follows its own; upgrade the nodes when Renovate bumps
it.

## Backups

`talosctl` and `kubectl` use `~/.talos/config` and `~/.kube/config`; never point `TALOSCONFIG` into the repo.
`backup-configs.sh` uploads both, `gen/secrets.yaml` and the sealed-secrets keys to 1Password (`yggdrasil *`
documents; restore commands in its header). Run it on the host, as `op` needs the desktop app, after certificates are
renewed, after the controller adds a key (every 30 days) and after regenerating the cluster secrets:

```shell
sh backup-configs.sh -c yggdrasil
```

## Images and flashing

A board's schematic, node patches and scripts are in its directory (`rk1/`, `rpi4/`):

```shell
sh gen-image.sh -b rk1 -n jotunheim-0 -v v1.14.2   # and jotunheim-1..3
sh gen-image.sh -b rpi4 -n vanaheim-0 -v v1.14.2
```

Flash an RK1 through the BMC (firmware 2.0.0+ needs credentials for every command):

```shell
export TPI_HOST=turingpi TPI_USER=root TPI_PASS=turing
sh rk1/flash.sh jotunheim-0 1   # node, slot
```

A Raspberry Pi has no BMC: write the image to its SD card or USB SSD, and check with
`talosctl get links --insecure -n <ip>` that the interface name matches `rpi4/nodes/vanaheim-0.yaml`.

```shell
sudo dd if=gen/vanaheim-0.metal-arm64.raw of=/dev/rdiskN bs=4m status=progress
```

The i5-10600k (`midgard-0`) boots in legacy BIOS mode, always from the NVMe, whose GRUB (from Ubuntu, on its first
two partitions, which stay) loads the Talos GRUB config from `sda`. Upgrades come from the installer image in its node
file, which holds the schematic of `i5-10600k/gen-schematic-id.sh`: update it when the extensions change. Install it
from Ubuntu, over SSH:

```shell
sh gen-image.sh -b i5-10600k -n midgard-0 -v v1.14.5
scp gen/midgard-0.metal-amd64.raw davy@192.168.1.44:/tmp/
```

On Ubuntu, write the image and add a GRUB entry, then boot Talos once; a reboot returns to Ubuntu:

```shell
sudo vgchange -an ubuntu-vg
sudo dd if=/tmp/midgard-0.metal-amd64.raw of=/dev/sda bs=4M conv=fsync status=progress
sudo tee -a /etc/grub.d/40_custom <<'EOF'
menuentry "Talos" --id talos {
  insmod part_gpt
  insmod xfs
  search --no-floppy --set=root --label BOOT
  configfile /grub/grub.cfg
}
EOF
sudo sed -i -e 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=saved/' -e 's/^GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=menu/' \
  -e 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=5/' /etc/default/grub
sudo update-grub && sudo grub-set-default 0 && sudo grub-reboot talos && sudo reboot
```

Check in maintenance mode that only `sda` matches the `diskSelector` (`talosctl get disks --insecure -n <ip>`), then
apply the config. Once the node is healthy, `talosctl reboot` back to Ubuntu and make Talos the default with
`sudo grub-set-default talos`.

## Bootstrap

`gen-talosconfig.sh` generates the cluster secrets once (if missing) and the talosconfig, merges it into
`~/.talos/config`, and points it at a node, as the VIP (`endpoint` in `patches/cluster.yaml`) only comes up after the
bootstrap. `apply-config.sh` generates a node's config and applies it, retrying with `--insecure` in maintenance
mode.

```shell
sh gen-talosconfig.sh -c yggdrasil -n jotunheim-0
sh apply-config.sh -b rk1 -c yggdrasil -n jotunheim-0 -t controlplane   # and jotunheim-1, jotunheim-2
sh apply-config.sh -b rk1 -c yggdrasil -n jotunheim-3 -t worker
sh apply-config.sh -b i5-10600k -c yggdrasil -n midgard-0 -t worker
talosctl bootstrap --nodes jotunheim-0
talosctl config endpoint $(sed -n 's|^endpoint: https://\(.*\):6443|\1|p' patches/cluster.yaml)
talosctl config nodes jotunheim-0 jotunheim-1 jotunheim-2 jotunheim-3
talosctl kubeconfig --nodes jotunheim-0
talosctl health
```

## Upgrades

One node at a time, control plane first; check it is healthy before the next:

```shell
sh upgrade-talos.sh -b rk1 -n jotunheim-0 -v v1.14.2
talosctl --nodes jotunheim-0 etcd members
kubectl get nodes
```

## Before GitOps

Install Cilium and sealed-secrets by hand. Argo CD then adopts both.

```shell
helm repo add cilium https://helm.cilium.io/
helm install cilium cilium/cilium --version 1.19.9 --namespace kube-system \
    --set ipam.mode=kubernetes \
    --set kubeProxyReplacement=true \
    --set securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
    --set securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
    --set cgroup.autoMount.enabled=false \
    --set cgroup.hostRoot=/sys/fs/cgroup \
    --set k8sServiceHost=localhost \
    --set k8sServicePort=7445

helm repo add sealed-secrets https://bitnami.github.io/sealed-secrets
helm install sealed-secrets sealed-secrets/sealed-secrets --version 2.20.0 --namespace kube-system \
    --set-string fullnameOverride=sealed-secrets-controller
```

### Sealed-secrets keys

Every SealedSecret, including Argo CD's repo key, only decrypts with the controller's keys. Restore them right after
installing sealed-secrets, before Argo CD:

```shell
op document get "yggdrasil sealed-secrets keys" | kubectl apply -f -
kubectl -n kube-system rollout restart deploy/sealed-secrets-controller
kubectl -n kube-system logs deploy/sealed-secrets-controller | grep "registered private key"
```

The log must list every restored key. Skip a key that logs `tls: private key does not match public key`. A new key
may stay next to the old ones; back it up once something is sealed with it.

### Argo CD

Install it with chart defaults (the repo's values need CRDs that don't exist yet), then hand over to the
ApplicationSet, which creates every app, including `argocd`, which adopts this release:

```shell
helm repo add argo https://argoproj.github.io/argo-helm
helm install argocd argo/argo-cd --version 9.7.1 -n argocd --create-namespace --wait
helm dependency update ../kubernetes/core/argocd
helm template argocd ../kubernetes/core/argocd -n argocd \
    -s templates/applicationset.yaml | kubectl apply -f -
```

Apps whose first sync needs CRDs from other apps fail once and are not retried: sync them by hand when
`sealed-secrets`, `envoy-gateway` and `prometheus-crd` are healthy. The UI, until its route works:

```shell
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
kubectl port-forward service/argocd-server -n argocd 8080:443
```
