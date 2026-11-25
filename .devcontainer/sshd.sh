#!/bin/sh
set -e
#
# Starts sshd for the desktop app's SSH sessions, with a host key that outlives the container and the container's
# environment, which SSH sessions don't get otherwise, and Remote Control for the Claude app.

mkdir -p /etc/ssh/keys /run/sshd
[ -f /etc/ssh/keys/ssh_host_ed25519_key ] || ssh-keygen -q -t ed25519 -N "" -f /etc/ssh/keys/ssh_host_ed25519_key

printf 'SetEnv "PATH=%s" "MISE_DATA_DIR=%s" "MISE_TRUSTED_CONFIG_PATHS=%s" "CLAUDE_CONFIG_DIR=%s" "GRAFANA_MCP_TOKEN=%s"\n' \
    "${PATH}" "${MISE_DATA_DIR}" "${MISE_TRUSTED_CONFIG_PATHS}" "${CLAUDE_CONFIG_DIR}" "${GRAFANA_MCP_TOKEN:-}" \
    > /etc/ssh/sshd_config.d/env.conf
chmod 600 /etc/ssh/sshd_config.d/env.conf

# Remote Control for the phone; it only starts once an interactive `claude` in /workspace has trusted the folder and
# enabled Remote Control, and gives up after a long network outage, hence the loop
(
    cd /workspace
    while true; do
        claude remote-control --name homelab < /dev/null >> /var/log/remote-control.log 2>&1 || true
        sleep 60
    done
) &

exec /usr/sbin/sshd -D -e
