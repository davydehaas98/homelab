#!/bin/sh
#
# Exports the secrets of terraform/arr as TF_VAR_* in the current shell, read from the apps in the cluster: the API
# keys from their config, the Discord webhooks from their API. Prowlarr only returns the NZBgeek key masked, so that
# one is asked for without echo, unless TF_VAR_nzbgeek_api_key is set already. Nothing is printed or written to disk.
# Needs `kubectl` with access to the cluster, and `yq`. Run it in the dev container (.devcontainer/README.md).
#
# Usage: . scripts/arr-env.sh

arr_exec() {
    kubectl -n media-server exec "$1-0" -- sh -c "$2"
}

arr_api_key() {
    arr_exec "$1" "sed -n 's:.*<ApiKey>\(.*\)</ApiKey>.*:\1:p' /config/config.xml"
}

# Usage: arr_web_hook_url <app> <port> <api version> <api key>
arr_web_hook_url() {
    arr_exec "$1" "curl -s -H 'X-Api-Key: $4' http://localhost:$2/api/$3/notification" |
        yq -p json '.[] | select(.implementation == "Discord") | .fields[] | select(.name == "webHookUrl") | .value'
}

TF_VAR_sonarr_api_key=$(arr_api_key sonarr)
TF_VAR_radarr_api_key=$(arr_api_key radarr)
TF_VAR_lidarr_api_key=$(arr_api_key lidarr)
TF_VAR_prowlarr_api_key=$(arr_api_key prowlarr)
TF_VAR_sabnzbd_api_key=$(arr_exec sabnzbd "sed -n 's/^api_key = //p' /config/sabnzbd.ini" | head -1)
TF_VAR_sonarr_discord_web_hook_url=$(arr_web_hook_url sonarr 8989 v3 "${TF_VAR_sonarr_api_key}")
TF_VAR_radarr_discord_web_hook_url=$(arr_web_hook_url radarr 7878 v3 "${TF_VAR_radarr_api_key}")
TF_VAR_lidarr_discord_web_hook_url=$(arr_web_hook_url lidarr 8686 v1 "${TF_VAR_lidarr_api_key}")

if [ -z "${TF_VAR_nzbgeek_api_key}" ]; then
    printf "NZBgeek API key: "
    stty -echo
    read -r TF_VAR_nzbgeek_api_key
    stty echo
    echo
fi

export TF_VAR_sonarr_api_key TF_VAR_radarr_api_key TF_VAR_lidarr_api_key TF_VAR_prowlarr_api_key \
    TF_VAR_sabnzbd_api_key TF_VAR_sonarr_discord_web_hook_url TF_VAR_radarr_discord_web_hook_url \
    TF_VAR_lidarr_discord_web_hook_url TF_VAR_nzbgeek_api_key

for ARR_VAR in sonarr_api_key radarr_api_key lidarr_api_key prowlarr_api_key sabnzbd_api_key \
    sonarr_discord_web_hook_url radarr_discord_web_hook_url lidarr_discord_web_hook_url nzbgeek_api_key; do
    eval "[ -n \"\${TF_VAR_${ARR_VAR}}\" ]" || echo "Warning: TF_VAR_${ARR_VAR} is empty"
done
unset ARR_VAR
