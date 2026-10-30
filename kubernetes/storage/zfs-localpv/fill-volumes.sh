#!/bin/sh
set -e
#
# Creates the datasets of the static volumes in values.yaml on midgard-0 and fills each from its `source` on `tank`
# (an iSCSI image, loop-mounted read-only, or an NFS folder), four at a time, from a privileged pod on the node. Run it
# in the dev container during the cutover, with the apps stopped and before their claims exist; a rerun copies only
# the changes. Needs `kubectl` and `yq`.
#
# Usage: sh kubernetes/storage/zfs-localpv/fill-volumes.sh [<name> ...]

cd "$(dirname "$0")"

POD=fill-volumes
NAMESPACE=zfs-localpv

# One volume, run by the loop below: name, pool, size, source
if [ "$1" = "--one" ]; then
    kubectl -n ${NAMESPACE} exec -i ${POD} -- sh -s -- "$2" "$3" "$4" "$5" <<'EOF'
set -e
name=$1 pool=$2 size=$3 source=$4
dataset=${pool}/k8s/${name}
target=/var/mnt/migrate/${name}
z() { chroot /host zfs "$@"; }

z list -H -o name "${dataset}" > /dev/null 2>&1 || z create -o quota="${size%i}" "${dataset}"
z set mountpoint="${target}" "${dataset}"
z mount "${dataset}" 2> /dev/null || true

case ${source} in
    *.img)
        mkdir -p "/src/${name}"
        mount -o loop,ro "/host/var/mnt/tank/${source}" "/src/${name}"
        from=/src/${name}/ ;;
    *) from=/host/var/mnt/tank/${source}/ ;;
esac

rsync -aHA --numeric-ids --delete --exclude=/lost+found "${from}" "/host${target}/"

case ${source} in
    *.img) umount "/src/${name}" ;;
esac
# The driver mounts the dataset itself
z set mountpoint=legacy "${dataset}"
echo "${name}: filled"
EOF
    exit
fi

echo "
Starting pod '${POD}' on midgard-0 ..
"
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: ${POD}
  namespace: ${NAMESPACE}
spec:
  nodeName: midgard-0
  restartPolicy: Never
  tolerations:
    - operator: Exists
  containers:
    - name: fill
      image: docker.io/library/alpine:3.22
      command: [sh, -c, "apk add --no-cache rsync > /dev/null && touch /ready && sleep infinity"]
      securityContext:
        privileged: true
      volumeMounts:
        - name: host
          mountPath: /host
  volumes:
    - name: host
      hostPath:
        path: /
EOF
until kubectl -n ${NAMESPACE} exec ${POD} -- test -f /ready 2> /dev/null; do sleep 5; done

# The volumes to fill: all, or the names given
yq -r '.volumes[] | [.name, .pool, .size, .source] | @tsv' values.yaml |
    while read -r name pool size source; do
        if [ $# -eq 0 ] || echo " $* " | grep -q " ${name} "; then
            echo "${name} ${pool} ${size} ${source}"
        fi
    done |
    xargs -P 4 -L 1 sh fill-volumes.sh --one

kubectl -n ${NAMESPACE} delete pod ${POD} --wait=false

echo "
Filled the volumes. Check the apps once they run.
"
