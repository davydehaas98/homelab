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
curl -LOk https://github.com/nberlee/talos/releases/download/v1.7.6/metal-arm64.raw.xz
unxz metal-arm64.raw.xz

tpi flash -i /mnt/sdcard/metal-arm64.raw -n 1
tpi flash -i /mnt/sdcard/metal-arm64.raw -n 2
tpi flash -i /mnt/sdcard/metal-arm64.raw -n 3
tpi flash -i /mnt/sdcard/metal-arm64.raw -n 4
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
export NODE_IP="192.168.2.32"
export CLUSTER_ENDPOINT="https://${NODE_IP}:6443"

# Talosconfig
talosctl gen secrets -o gen/secrets.yaml
talosctl gen config \
    $CLUSTER_NAME $CLUSTER_ENDPOINT \
    --with-secrets gen/secrets.yaml \
    --output-types talosconfig \
    --output gen/talosconfig
    --force

talosctl config merge gen/talosconfig
```

```shell
./gen-config.sh -c test \
    -k 1.30.0 \
    -i 192.168.2.32 \
    -t controlplane -n 0
```

```shell
talosctl -n $NODE_IP dashboard
talosctl -n $NODE_IP kubeconfig
```