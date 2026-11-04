#!/bin/sh
set -e
#
# Uploads the talosconfig, kubeconfig, Talos secrets and sealed-secrets keys to 1Password, without printing them.
#
# Usage: sh backup-configs.sh -c <cluster-name>
#
# Restore (from talos/):
#   op document get "<cluster-name> talosconfig" --out-file "$HOME/.talos/config"
#   op document get "<cluster-name> kubeconfig" --out-file "$HOME/.kube/config"
#   op document get "<cluster-name> talos secrets" --out-file gen/secrets.yaml
#   op document get "<cluster-name> sealed-secrets keys" | kubectl apply -f -
#   kubectl -n kube-system rollout restart deployment sealed-secrets-controller

cd "$(dirname "$0")"

while getopts c: flag;
do
    case ${flag} in
        c) CLUSTER_NAME=${OPTARG} ;;
        *) exit 1 ;;
    esac
done

upload() {
    TITLE="${CLUSTER_NAME} $1"
    # Keeps `op item get` from consuming the piped contents
    if op item get "${TITLE}" < /dev/null > /dev/null 2>&1; then
        op document edit "${TITLE}" - --file-name "$2" > /dev/null
    else
        op document create - --title "${TITLE}" --file-name "$2" > /dev/null
    fi
    echo "Uploaded '${TITLE}'"
}

# `op` does not find stdin with a redirect
cat "${TALOSCONFIG:-$HOME/.talos/config}" | upload talosconfig config
cat gen/secrets.yaml | upload "talos secrets" secrets.yaml

# Captured first, so a kubectl failure does not upload an empty document
KUBECONFIG_CONTENT=$(kubectl config view --minify --flatten --context "admin@${CLUSTER_NAME}")
printf '%s\n' "${KUBECONFIG_CONTENT}" | upload kubeconfig config

SEALED_SECRETS_KEYS=$(kubectl get secret \
    --context "admin@${CLUSTER_NAME}" \
    --namespace kube-system \
    --selector sealedsecrets.bitnami.com/sealed-secrets-key \
    --output yaml)
# An empty list would overwrite a good backup
case "${SEALED_SECRETS_KEYS}" in
    *"kind: Secret"*) ;;
    *) echo "No sealed-secrets keys found" >&2; exit 1 ;;
esac
printf '%s\n' "${SEALED_SECRETS_KEYS}" | upload "sealed-secrets keys" sealed-secrets-keys.yaml
