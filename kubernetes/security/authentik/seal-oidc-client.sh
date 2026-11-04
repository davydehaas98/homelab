#!/bin/sh
set -e
#
# Seals a random OIDC client ID and secret for Authentik and the app, without printing them.
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

PREFIX=$(echo "${SLUG}" | tr 'a-z-' 'A-Z_')
CLIENT_ID=$(openssl rand -hex 20)
CLIENT_SECRET=$(openssl rand -hex 32)

sealed_secret() {
    jq -n --arg name "$1" --arg namespace "$2" --arg idKey "$3" --arg secretKey "$4" \
        --arg id "${CLIENT_ID}" --arg secret "${CLIENT_SECRET}" \
        '{apiVersion: "v1", kind: "Secret", type: "Opaque", metadata: {name: $name, namespace: $namespace},
          stringData: {($idKey): $id, ($secretKey): $secret}}' |
        kubeseal --controller-namespace kube-system --controller-name sealed-secrets-controller --format yaml
}

sealed_secret "authentik-oidc-${SLUG}" authentik "${PREFIX}_CLIENT_ID" "${PREFIX}_CLIENT_SECRET" \
    > "templates/oidc-client-${SLUG}.yaml"
sealed_secret "${SLUG}-oidc-credentials" "${NAMESPACE}" client-id client-secret \
    > "../../${APP}/templates/oidc-credentials.yaml"
echo "Sealed the OIDC client '${SLUG}'"
