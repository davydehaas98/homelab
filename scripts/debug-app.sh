#!/bin/sh
#
# Read-only triage of an Argo CD app: its Application, SealedSecrets, pods, events and routes.
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

echo "== SealedSecrets in ${NAMESPACE}"
kubectl -n "${NAMESPACE}" get sealedsecret -o json 2> /dev/null |
    jq -r '.items[] | .metadata.name + ": " + ([.status.conditions[]? | .type + "=" + .status + " " + (.message // "")] | join("; "))'

echo "== Pods in ${NAMESPACE}"
kubectl -n "${NAMESPACE}" get pods -o wide

echo "== Warning events in ${NAMESPACE}"
kubectl -n "${NAMESPACE}" get events --field-selector type=Warning --sort-by=.lastTimestamp 2>&1 | tail -n 15

echo "== Previous logs of restarting pods"
for POD in $(kubectl -n "${NAMESPACE}" get pods -o json | jq -r '.items[] | select(any(.status.containerStatuses[]?; .restartCount > 0)) | .metadata.name'); do
    echo "-- ${POD}"
    kubectl -n "${NAMESPACE}" logs "${POD}" --previous --tail=20 2>&1
done

echo "== HTTPRoutes in ${NAMESPACE}"
kubectl -n "${NAMESPACE}" get httproute -o json 2> /dev/null |
    jq -r '.items[] | .metadata.name + ": " + ([.status.parents[]?.conditions[]? | .type + "=" + .status] | join(" "))'

echo "== SecurityPolicies in ${NAMESPACE}"
kubectl -n "${NAMESPACE}" get securitypolicy -o json 2> /dev/null |
    jq -r '.items[] | .metadata.name + ": " + ([.status.ancestors[]?.conditions[]? | .type + "=" + .status + " " + (.message // "")] | join("; "))'
