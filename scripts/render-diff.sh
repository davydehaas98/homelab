#!/bin/sh
set -e
#
# Renders apps at a git ref and in the working tree, and prints the difference (diff -u), to see what a change or a
# chart bump does to the manifests before pushing. Both sides are built in a temporary directory, so the working tree
# and its charts/ stay as they are. Run it in the dev container (.devcontainer/README.md).
#
# Usage: sh scripts/render-diff.sh [-r <ref>] <group>/<app> [<group>/<app> ...]   (ref: default HEAD)

cd "$(dirname "$0")/.."

REF=HEAD
while getopts r: flag;
do
    case ${flag} in
        r) REF=${OPTARG} ;;
        *) exit 1 ;;
    esac
done
shift $((OPTIND - 1))
[ $# -gt 0 ] || { grep '^# Usage' "$0" >&2; exit 1; }

TMP=$(mktemp -d)
trap 'rm -rf "${TMP}"' EXIT
mkdir -p "${TMP}/old" "${TMP}/new"
git archive "${REF}" kubernetes | tar x -C "${TMP}/old"
tar cf - --exclude='*/charts/*' kubernetes | tar x -C "${TMP}/new"

render() {
    dir="$1/kubernetes/$2"
    [ -f "${dir}/Chart.yaml" ] || { echo "# not in this version" ; return; }
    for url in $(yq -N '.dependencies[].repository' "${dir}/Chart.yaml" | grep '^http' || true); do
        helm repo add "$(echo "${url}" | md5sum | cut -c1-8)" "${url}" --force-update > /dev/null
    done
    helm dependency build "${dir}" > /dev/null
    NAMESPACE=$(yq '.namespace // ""' "${dir}/argocd.yaml" 2> /dev/null)
    helm template "$(basename "$2")" "${dir}" --namespace "${NAMESPACE:-$(basename "$2")}" \
        --api-versions monitoring.coreos.com/v1
}

for APP in "$@"; do
    if [ ! -f "${TMP}/old/kubernetes/${APP}/Chart.yaml" ] && [ ! -f "${TMP}/new/kubernetes/${APP}/Chart.yaml" ]; then
        echo "kubernetes/${APP} is neither at ${REF} nor in the working tree" >&2
        exit 1
    fi
    render "${TMP}/old" "${APP}" > "${TMP}/old.yaml"
    render "${TMP}/new" "${APP}" > "${TMP}/new.yaml"
    if diff -q "${TMP}/old.yaml" "${TMP}/new.yaml" > /dev/null; then
        echo "== ${APP}: render identical"
    else
        echo "== ${APP}: render differs"
        diff -u --label "${APP}@${REF}" --label "${APP} (working tree)" "${TMP}/old.yaml" "${TMP}/new.yaml" || true
    fi
done
