#!/bin/sh
set -eu -o pipefail
#
# The nightly backup of the CronJob in templates/backup.yaml. Dumps the databases to its volume at /dumps, then copies
# every dataset of `fast` to `tank`, see README.md. Exits non-zero if any of it failed, after trying the rest.

CONFIG=${CONFIG:-/config}
DUMPS=${DUMPS:-/dumps}
SOURCE=${SOURCE:-fast/k8s}
TARGET=${TARGET:-tank/backup/fast}
KEEP=${KEEP:-14}

now=$(date +%Y%m%d-%H%M%S)
failed=0

z() { chroot /host zfs "$@"; }

# kubectl exec can end its stream early and still exit 0, which cut off Immich's dump every time when it was sent
# uncompressed, so gzip runs in the database's pod, and a dump only counts when it ends as pg_dump ends a dump
complete() {
    [ "$(gzip -dc "$1" | tail -n 8 | grep -c 'dump complete' || true)" -gt 0 ]
}

# One database per line of the `databases` file: name, namespace, selector, container, command
while read -r name namespace selector container command; do
    mkdir -p "${DUMPS}/${name}"
    file=${DUMPS}/${name}/${name}-${now}.sql.gz
    dumped=0
    for try in 1 2 3; do
        pod=$(kubectl -n "${namespace}" get pod -l "${selector}" -o name | sed -n 1p) || true
        if kubectl -n "${namespace}" exec "${pod}" -c "${container}" -- sh -c "${command} | gzip" > "${file}.tmp" &&
            complete "${file}.tmp"; then
            dumped=1
            break
        fi
        echo "${name}: try ${try} incomplete"
    done
    if [ "${dumped}" = 1 ]; then
        mv "${file}.tmp" "${file}"
        ls -1t "${DUMPS}/${name}" | tail -n +$((KEEP + 1)) | while read -r old; do
            rm -f "${DUMPS}/${name}/${old}"
        done
        echo "${name}: dumped $(ls -l "${file}" | awk '{print $5}') bytes"
    else
        rm -f "${file}.tmp"
        echo "${name}: dump failed"
        failed=1
    fi
done < "${CONFIG}/databases"

# The target's parents hold no data and are not mounted
parent=${TARGET%/*}
z list -H -o name "${parent}" > /dev/null 2>&1 || z create -o mountpoint=none "${parent}"
z list -H -o name "${TARGET}" > /dev/null 2>&1 || z create "${TARGET}"

names=$(z list -H -r -d 1 -t filesystem -o name "${SOURCE}" | tail -n +2 | sed "s#^${SOURCE}/##" |
    { grep -vxF -f "${CONFIG}/exclude" || true; })

# One command, so all datasets are snapshotted at the same moment
snapshots=""
for name in ${names}; do
    snapshots="${snapshots} ${SOURCE}/${name}@backup-${now}"
done
# shellcheck disable=SC2086
z snapshot ${snapshots}

for name in ${names}; do
    source=${SOURCE}/${name}
    target=${TARGET}/${name}
    last=$({ z list -H -d 1 -t snapshot -o name -S creation "${target}" 2> /dev/null || true; } |
        sed -n 1p | cut -d@ -f2)

    if [ -n "${last}" ]; then
        from="-i @${last}"
    else
        from=""
    fi
    # shellcheck disable=SC2086
    if ! z send -c ${from} "${source}@backup-${now}" | z receive -u "${target}"; then
        # Keeps the last snapshot both sides have, for the next run
        echo "${name}: copy failed"
        z destroy "${source}@backup-${now}"
        failed=1
        continue
    fi

    # A snapshot counts towards the quota of its volume, so `fast` keeps only the one the next run starts from
    z list -H -d 1 -t snapshot -o name "${source}" | { grep "@backup-" | grep -v "@backup-${now}\$" || true; } |
        while read -r old; do
            z destroy "${old}"
        done
    z list -H -d 1 -t snapshot -o name -S creation "${target}" | grep "@backup-" | tail -n +$((KEEP + 1)) |
        while read -r old; do
            z destroy "${old}"
        done
    echo "${name}: copied"
done

exit "${failed}"
