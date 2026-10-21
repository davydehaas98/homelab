#!/bin/sh
set -e
#
# Seals the broker's accounts as the SealedSecret mosquitto-passwd (templates/mosquitto-passwd.yaml), the password file
# of mosquitto.conf. Asks the password of each account without echo (or reads them from stdin when it is not a terminal,
# one line per account), hashes them with mosquitto_passwd in the running broker pod, and seals the result: neither
# the passwords nor the hashes are printed or written to a file. Sealing replaces every account, so name all of them
# each time. DRY_RUN=1 prints the accounts and the hash scheme instead of sealing. Needs kubectl and kubeseal with access
# to the cluster: run it from the repo root in the dev container (.devcontainer/README.md).
#
# Usage: sh kubernetes/home/mosquitto/seal-passwd.sh <account> [<account> ...]

cd "$(dirname "$0")/../../.."

[ $# -gt 0 ] || { grep '^# Usage' "$0" >&2; exit 1; }
for ACCOUNT in "$@"; do
    case "${ACCOUNT}" in
        ''|*[!a-z0-9-]*) echo "account must be lowercase letters, digits and dashes, got '${ACCOUNT}'" >&2; exit 1 ;;
    esac
done

[ -t 0 ] && trap 'stty echo' EXIT INT TERM
LINES=""
for ACCOUNT in "$@"; do
    if [ -t 0 ]; then
        stty -echo
        printf 'Password of %s: ' "${ACCOUNT}" >&2; read -r PASSWORD; echo >&2
        printf 'Again: ' >&2; read -r AGAIN; echo >&2
        stty echo
        [ "${PASSWORD}" = "${AGAIN}" ] || { echo "the passwords of ${ACCOUNT} differ" >&2; exit 1; }
    else
        read -r PASSWORD
    fi
    [ -n "${PASSWORD}" ] || { echo "the password of ${ACCOUNT} is empty" >&2; exit 1; }
    LINES="${LINES}${ACCOUNT} ${PASSWORD}
"
done

# mosquitto_passwd is in the broker's image, not in the dev container
hash() {
    printf '%s' "${LINES}" | kubectl -n mosquitto exec -i statefulset/mosquitto -- sh -c \
        'f=$(mktemp); while read -r u p; do mosquitto_passwd -b "$f" "$u" "$p"; done; cat "$f"; rm -f "$f"'
}

if [ -n "${DRY_RUN}" ]; then
    hash | sed 's/^\([^:]*\):\(\$[0-9]*\$\).*/\1: \2 hash/'
else
    hash | sh scripts/seal-secret.sh -n mosquitto-passwd -N mosquitto -a home/mosquitto -k passwd
fi
