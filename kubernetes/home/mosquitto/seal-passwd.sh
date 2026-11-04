#!/bin/sh
set -e
#
# Seals the broker's accounts into templates/mosquitto-passwd.yaml, hashed in the broker pod and never printed.
# Name every account each time. DRY_RUN=1 prints the accounts instead.
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

# mosquitto_passwd is only in the broker's image
hash() {
    printf '%s' "${LINES}" | kubectl -n mosquitto exec -i statefulset/mosquitto -- sh -c \
        'f=$(mktemp); while read -r u p; do mosquitto_passwd -b "$f" "$u" "$p"; done; cat "$f"; rm -f "$f"'
}

if [ -n "${DRY_RUN}" ]; then
    hash | sed 's/^\([^:]*\):\(\$[0-9]*\$\).*/\1: \2 hash/'
else
    hash | sh scripts/seal-secret.sh -n mosquitto-passwd -N mosquitto -a home/mosquitto -k passwd
fi
