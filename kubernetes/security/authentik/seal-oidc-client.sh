#!/bin/sh
set -e
#
# Seals one random client ID and secret for an OIDC client into both Secrets: the one Authentik reads
# (templates/oidc-client-<slug>.yaml) and the one of the app (<app>/templates/oidc-credentials.yaml). The values stay
# in the shell and are never printed or written in plain text. Running it again replaces both, so the client gets a
# new pair. Needs `kubeseal` with access to the cluster, `jq` and `openssl`.
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

# Prints a sealed Secret holding the pair under the given keys: <name> <namespace> <id key> <secret key>
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
