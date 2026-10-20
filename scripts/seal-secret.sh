#!/bin/sh
set -e
#
# Seals a Secret into kubernetes/<group>/<app>/templates/<name>.yaml. The values are asked for without echo (or read
# from stdin when it is not a terminal, one line per key, or the whole of stdin for a single key, which then may span
# several lines), and never printed or written in plain text. A SealedSecret only decrypts under
# the name and namespace it was sealed for, and cannot be edited. With -m the keys of the live Secret are kept and
# the given keys replaced or added, so a key can be added to an existing Secret. Needs `kubeseal` and `jq`, and
# `kubectl` for -m, with access to the cluster. Run it in the dev container (.devcontainer/README.md).
#
# Usage: sh scripts/seal-secret.sh -n <name> -N <namespace> -a <group>/<app> -k <key> [-k <key> ...] [-m]

cd "$(dirname "$0")/.."

KEYS=""
while getopts n:N:a:k:m flag;
do
    case ${flag} in
        n) NAME=${OPTARG} ;;
        N) NAMESPACE=${OPTARG} ;;
        a) APP=${OPTARG} ;;
        k) KEYS="${KEYS} ${OPTARG}" ;;
        m) MERGE=1 ;;
        *) exit 1 ;;
    esac
done

if [ -z "${NAME}" ] || [ -z "${NAMESPACE}" ] || [ -z "${APP}" ] || [ -z "${KEYS}" ]; then
    echo "Usage: sh scripts/seal-secret.sh -n <name> -N <namespace> -a <group>/<app> -k <key> [-k <key> ...] [-m]" >&2
    exit 1
fi

if [ -n "${MERGE}" ]; then
    SECRET=$(kubectl -n "${NAMESPACE}" get secret "${NAME}" -o json |
        jq '{apiVersion: "v1", kind: "Secret", type: .type, metadata: {name: .metadata.name, namespace: .metadata.namespace}, data: .data}')
else
    SECRET=$(jq -n --arg name "${NAME}" --arg namespace "${NAMESPACE}" \
        '{apiVersion: "v1", kind: "Secret", type: "Opaque", metadata: {name: $name, namespace: $namespace}}')
fi

trap 'stty echo 2> /dev/null || true' EXIT INT
for KEY in ${KEYS}; do
    if [ -t 0 ]; then
        printf 'Value of %s: ' "${KEY}" >&2
        stty -echo
        IFS= read -r VALUE
        stty echo
        printf '\n' >&2
    elif [ "$(set -- ${KEYS}; echo $#)" -eq 1 ]; then
        VALUE=$(cat)
    else
        # Without a trailing newline `read` fails, but still sets the value
        IFS= read -r VALUE || [ -n "${VALUE}" ]
    fi
    # Through the environment, so the value is not in a process list
    SECRET=$(printf '%s' "${SECRET}" | KEY="${KEY}" VALUE="${VALUE}" jq '.stringData[env.KEY] = env.VALUE | del(.data[env.KEY])')
done
unset VALUE

printf '%s' "${SECRET}" |
    kubeseal --controller-namespace kube-system --controller-name sealed-secrets-controller --format yaml \
    > "kubernetes/${APP}/templates/${NAME}.yaml"
echo "Sealed kubernetes/${APP}/templates/${NAME}.yaml"
