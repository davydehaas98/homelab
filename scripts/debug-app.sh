#!/bin/sh
#
# Read-only triage of an Argo CD app: its Application (sync, health, conditions), the SealedSecrets, pods and warning
# events in its namespace, and the status of its routes. The app is the name of the Application, the directory name
# under kubernetes/<group>/. Nothing is changed. Needs `kubectl` and `jq` with access to the cluster. Run it in the dev
# container (.devcontainer/README.md).
#
# Usage: sh scripts/debug-app.sh -a <app>

while getopts a: flag;
do
    case ${flag} in
        a) APP=${OPTARG} ;;
        *) exit 1 ;;
    esac
done

if [ -z "${APP}" ]; then
    echo "Usage: sh scripts/debug-app.sh -a <app>" >&2
    exit 1
fi

echo "== Application"
if ! kubectl -n argocd get application "${APP}" -o json > /tmp/debug-app.json; then
    echo "Not deployed: it needs deploy: true in chart/values.yaml and a directory under kubernetes/"
    exit 1
fi
jq '{project: .spec.project, namespace: .spec.destination.namespace, sync: .status.sync.status, health: .status.health.status,
     conditions: .status.conditions, operation: .status.operationState.message}' /tmp/debug-app.json
NAMESPACE=$(jq -r '.spec.destination.namespace' /tmp/debug-app.json)
rm -f /tmp/debug-app.json

echo "== SealedSecrets in ${NAMESPACE}"
kubectl -n "${NAMESPACE}" get sealedsecret -o json 2> /dev/null |
    jq -r '.items[] | .metadata.name + ": " + ([.status.conditions[]? | .type + "=" + .status + " " + (.message // "")] | join("; "))'

echo "== Pods in ${NAMESPACE}"
kubectl -n "${NAMESPACE}" get pods -o wide

echo "== Warning events in ${NAMESPACE}"
kubectl -n "${NAMESPACE}" get events --field-selector type=Warning --sort-by=.lastTimestamp 2>&1 | tail -n 15

echo "== Previous logs of restarting pods"
for POD in $(kubectl -n "${NAMESPACE}" get pods -o json |
    jq -r '.items[] | select(any(.status.containerStatuses[]?; .restartCount > 0)) | .metadata.name'); do
    echo "-- ${POD}"
    kubectl -n "${NAMESPACE}" logs "${POD}" --previous --tail=20 2>&1
done

echo "== HTTPRoutes in ${NAMESPACE}"
kubectl -n "${NAMESPACE}" get httproute -o json 2> /dev/null |
    jq -r '.items[] | .metadata.name + ": " + ([.status.parents[]?.conditions[]? | .type + "=" + .status] | join(" "))'

echo "== SecurityPolicies in ${NAMESPACE}"
kubectl -n "${NAMESPACE}" get securitypolicy -o json 2> /dev/null |
    jq -r '.items[] | .metadata.name + ": " + ([.status.ancestors[]?.conditions[]? | .type + "=" + .status + " " + (.message // "")] | join("; "))'
