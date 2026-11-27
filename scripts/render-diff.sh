#!/bin/sh
set -e
#
# Prints the difference between the apps' manifests, CRDs included, at a git ref and in the working tree, or at a second
# ref with -n. The helm.sh/chart label is left out, as a chart bump changes it on every resource.
#
# Usage: sh scripts/render-diff.sh [-r <ref>] [-n <ref>] <group>/<app> [<group>/<app> ...]   (-r: default HEAD)

cd "$(dirname "$0")/.."

REF=HEAD
while getopts r:n: flag;
do
    case ${flag} in
        r) REF=${OPTARG} ;;
        n) NEW_REF=${OPTARG} ;;
        *) exit 1 ;;
    esac
done
shift $((OPTIND - 1))
[ $# -gt 0 ] || { grep '^# Usage' "$0" >&2; exit 1; }
NEW_LABEL=${NEW_REF:-the working tree}

TMP=$(mktemp -d)
trap 'rm -rf "${TMP}"' EXIT
mkdir -p "${TMP}/old" "${TMP}/new"
git archive "${REF}" kubernetes | tar x -C "${TMP}/old"
if [ -n "${NEW_REF}" ]; then
    git archive "${NEW_REF}" kubernetes | tar x -C "${TMP}/new"
else
    tar cf - --exclude='*/charts/*' --exclude='*/Chart.lock' kubernetes | tar x -C "${TMP}/new"
fi

render() {
    dir="$1/kubernetes/$2"
    [ -f "${dir}/Chart.yaml" ] || { echo "# not in this version" ; return; }
    helm dependency update "${dir}" > /dev/null
    NAMESPACE=""
    if [ -f "${dir}/argocd.yaml" ]; then
        NAMESPACE=$(yq '.namespace // ""' "${dir}/argocd.yaml")
    fi
    helm template "$(basename "$2")" "${dir}" --namespace "${NAMESPACE:-$(basename "$2")}" --include-crds \
        --api-versions monitoring.coreos.com/v1 | grep -v '^ *helm\.sh/chart: '
}

for APP in "$@"; do
    if [ ! -f "${TMP}/old/kubernetes/${APP}/Chart.yaml" ] && [ ! -f "${TMP}/new/kubernetes/${APP}/Chart.yaml" ]; then
        echo "kubernetes/${APP} is neither at ${REF} nor in ${NEW_LABEL}" >&2
        exit 1
    fi
    render "${TMP}/old" "${APP}" > "${TMP}/old.yaml"
    render "${TMP}/new" "${APP}" > "${TMP}/new.yaml"
    if diff -q "${TMP}/old.yaml" "${TMP}/new.yaml" > /dev/null; then
        echo "== ${APP}: render identical at ${REF} and ${NEW_LABEL}"
    else
        echo "== ${APP}: render differs between ${REF} and ${NEW_LABEL}"
        diff -u --label "${APP}@${REF}" --label "${APP} (${NEW_LABEL})" "${TMP}/old.yaml" "${TMP}/new.yaml" || true
    fi
done
