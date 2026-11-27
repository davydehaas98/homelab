#!/bin/sh
#
# Read-only triage of an Argo CD app: its Application, and of the resources it manages the SealedSecrets, pods, warning
# events and routes.
#
# Usage: sh scripts/debug-app.sh <app>

APP=$1
[ -n "${APP}" ] || { grep '^# Usage' "$0" >&2; exit 1; }

echo "== Application"
if ! APPLICATION=$(kubectl -n argocd get application "${APP}" -o json); then
    echo "Not deployed: it needs kubernetes/<group>/<app>/argocd.yaml with deploy: true"
    exit 1
fi
echo "${APPLICATION}" | jq '{project: .spec.project, namespace: .spec.destination.namespace, sync: .status.sync.status,
    health: .status.health.status, conditions: .status.conditions, operation: .status.operationState.message}'
NAMESPACE=$(echo "${APPLICATION}" | jq -r '.spec.destination.namespace')
RESOURCES=$(echo "${APPLICATION}" | jq -c '.status.resources // []')

# Prints the items of the given kind that the app manages, as JSON
managed() {
    kubectl -n "${NAMESPACE}" get "$1" -o json 2> /dev/null |
        jq -c --arg kind "$2" --argjson resources "${RESOURCES}" \
            '.items[] | select(.metadata.name as $name | $resources | any(.kind == $kind and .name == $name))'
}

echo "== SealedSecrets"
managed sealedsecret SealedSecret |
    jq -r '.metadata.name + ": " + ([.status.conditions[]? | .type + "=" + .status + " " + (.message // "")] | join("; "))'

echo "== Pods"
PODS=$(for KIND in Deployment StatefulSet DaemonSet Job; do
    managed "${KIND}" "${KIND}" | jq -r '.spec.selector.matchLabels | to_entries | map(.key + "=" + .value) | join(",")'
done | while read -r SELECTOR; do
    kubectl -n "${NAMESPACE}" get pods -l "${SELECTOR}" -o json | jq -c '.items[]'
done | jq -s 'unique_by(.metadata.name)')
echo "${PODS}" | jq -r '.[] | .metadata.name + "  " + .status.phase + "  " + (.spec.nodeName // "-") + "  " +
    ([.status.containerStatuses[]? | .name + ": ready=" + (.ready | tostring) + " restarts=" + (.restartCount | tostring) +
        (if .lastState.terminated then " last=" + .lastState.terminated.reason else "" end)] | join(", ")) +
    "  limits " + ([.spec.containers[] | .name + "=" + (.resources.limits // {} | to_entries | map(.key + ":" + .value) | join("/"))] | join(", "))'

echo "== Warning events"
kubectl -n "${NAMESPACE}" get events --field-selector type=Warning -o json |
    jq -r --argjson resources "${RESOURCES}" --argjson pods "${PODS}" '
        ([$resources[].name] + [$pods[].metadata.name]) as $names |
        [.items[] | select(.involvedObject.name as $name | $names | index($name))] | sort_by(.lastTimestamp)[-15:][] |
        (.lastTimestamp // .eventTime) + "  " + .involvedObject.kind + "/" + .involvedObject.name + "  " + .reason + ": " + .message'

echo "== Previous logs of restarting pods"
for POD in $(echo "${PODS}" | jq -r '.[] | select(any(.status.containerStatuses[]?; .restartCount > 0)) | .metadata.name'); do
    echo "-- ${POD}"
    kubectl -n "${NAMESPACE}" logs "${POD}" --previous --tail=20 2>&1
done

echo "== HTTPRoutes"
managed httproute HTTPRoute |
    jq -r '.metadata.name + ": " + ([.status.parents[]?.conditions[]? | .type + "=" + .status] | join(" "))'

echo "== SecurityPolicies"
managed securitypolicy SecurityPolicy |
    jq -r '.metadata.name + ": " + ([.status.ancestors[]?.conditions[]? | .type + "=" + .status + " " + (.message // "")] | join("; "))'
