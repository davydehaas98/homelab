# Sourced by validate.sh and render-diff.sh: builds the dependencies of the chart in $1 from its Chart.lock, adding
# the http repositories it names first, as `helm dependency build` needs them

build_deps() {
    for URL in $(yq -N '.dependencies[].repository' "$1/Chart.yaml" | grep '^http'); do
        helm repo add "$(echo "${URL}" | md5sum | cut -c1-8)" "${URL}" --force-update > /dev/null || return 1
    done
    helm dependency build "$1" > /dev/null
}
