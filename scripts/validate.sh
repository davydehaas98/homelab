#!/bin/sh
set -e
#
# Lints the plain YAML and renders the given apps; -t also validates Terraform.
#
# Usage: sh scripts/validate.sh [-t] [<group>/<app> ...]

cd "$(dirname "$0")/.."

while getopts t flag;
do
    case ${flag} in
        t) TERRAFORM=1 ;;
        *) exit 1 ;;
    esac
done
shift $((OPTIND - 1))

echo "Linting YAML.."
git ls-files -z '*.yaml' '*.yml' | xargs -0 yamllint

for APP in "$@"; do
    echo "Validating ${APP}.."
    helm dependency update "kubernetes/${APP}" > /dev/null
    helm lint "kubernetes/${APP}"
    if ! helm template "kubernetes/${APP}" --api-versions monitoring.coreos.com/v1 | grep -q '^kind: Namespace$'; then
        echo "Warning: the render of ${APP} has no Namespace, which then has to come from another app"
    fi
done

if [ -n "${TERRAFORM}" ]; then
    echo "Validating terraform.."
    for STACK in terraform/cloudflare/davydehaas.dev terraform/cloudflare/davydehaas.nl terraform/devopsarr; do
        (
            cd "${STACK}"
            [ -f .terraform.lock.hcl ] && LOCKED=1
            terraform init -backend=false > /dev/null
            terraform validate
            terraform fmt -check
            [ -n "${LOCKED}" ] || rm -f .terraform.lock.hcl
        )
    done
fi

echo "Valid"
