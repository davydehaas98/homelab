#!/bin/sh
#
# Lists the networks and port forwards of the gateway with their IDs, for the import blocks. Prints no secrets.
#
# Usage: sh ids.sh (in terraform/unifi), with the key from terraform.tfvars

[ -n "${TF_VAR_unifi_api_key}" ] || [ ! -f terraform.tfvars ] ||
    TF_VAR_unifi_api_key=$(sed -n 's/^unifi_api_key *= *"\(.*\)"$/\1/p' terraform.tfvars)

api() {
    curl -sk -H "X-API-KEY: ${TF_VAR_unifi_api_key}" "https://192.168.1.1/proxy/network/api/s/default/rest/$1"
}

echo "Networks:"
api networkconf | yq -p json '.data[] | select(.purpose != "wan") | "  " + ._id + "  " + .name + "  " + (.ip_subnet // "")'
echo "Port forwards:"
api portforward | yq -p json '.data[] | "  " + ._id + "  " + .name + "  " + .proto + " " + .dst_port + " -> " + .fwd + ":" + .fwd_port'
