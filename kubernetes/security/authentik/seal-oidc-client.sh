#!/bin/sh
set -e
#
# Seals a random OIDC client ID and secret into the app's Secret <slug>-oidc-credentials, without printing them. The
# annotations let kubernetes-replicator copy it to authentik, where values.yaml reads it with the prefix <slug>-.
#
# Usage: sh seal-oidc-client.sh -s <slug> -n <namespace> -a <group>/<app>

cd "$(dirname "$0")"

while getopts s:n:a: flag;
do
    case ${flag} in
        s) SLUG=${OPTARG} ;;
        n) NAMESPACE=${OPTARG} ;;
        a) APP=${OPTARG} ;;
        *) exit 1 ;;
    esac
done

if [ -z "${SLUG}" ] || [ -z "${NAMESPACE}" ] || [ -z "${APP}" ]; then
    echo "Usage: sh seal-oidc-client.sh -s <slug> -n <namespace> -a <group>/<app>" >&2
    exit 1
fi

jq -n --arg name "${SLUG}-oidc-credentials" --arg namespace "${NAMESPACE}" \
    --arg id "$(openssl rand -hex 20)" --arg secret "$(openssl rand -hex 32)" \
    '{apiVersion: "v1", kind: "Secret", type: "Opaque",
      metadata: {name: $name, namespace: $namespace, annotations: {"replicator.v1.mittwald.de/replication-allowed": "true",
        "replicator.v1.mittwald.de/replication-allowed-namespaces": "authentik"}},
      stringData: {"client-id": $id, "client-secret": $secret}}' |
    kubeseal --controller-namespace kube-system --controller-name sealed-secrets-controller --format yaml \
    > "../../${APP}/templates/oidc-credentials.yaml"
echo "Sealed the OIDC client '${SLUG}'"
