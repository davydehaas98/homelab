#!/bin/sh
#
# Lists the networks, Wi-Fi networks, port forwards and firewall policies of the gateway with their IDs, for the
# import blocks. Prints no secrets.
#
# Usage: sh ids.sh (in terraform/unifi), with the key from terraform.tfvars

[ -n "${TF_VAR_unifi_api_key}" ] || [ ! -f terraform.tfvars ] ||
    TF_VAR_unifi_api_key=$(sed -n 's/^unifi_api_key *= *"\(.*\)"$/\1/p' terraform.tfvars)

api() {
    curl -sk -H "X-API-KEY: ${TF_VAR_unifi_api_key}" "https://192.168.1.1/proxy/network/$1"
}

echo "Networks:"
api api/s/default/rest/networkconf | yq -p json '.data[] | select(.purpose != "wan") | "  " + ._id + "  " + .name + "  " + (.ip_subnet // "")'
echo "Wi-Fi networks:"
api api/s/default/rest/wlanconf | yq -p json '.data[] | "  " + ._id + "  " + .name'
echo "Port forwards:"
api api/s/default/rest/portforward | yq -p json '.data[] | "  " + ._id + "  " + .name + "  " + .proto + " " + .dst_port + " -> " + .fwd + ":" + .fwd_port'
echo "Firewall policies:"
api v2/api/site/default/firewall-policies | yq -p json '.[] | select(.predefined != true) | "  " + ._id + "  " + .name'
