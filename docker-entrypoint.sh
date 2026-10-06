#!/bin/sh
# SPDX-FileCopyrightText: © 2026 Kozea <contact@kozea.org>
# SPDX-License-Identifier: GPL-3.0-or-later

set -eu

HTPASSWD_FILE="${RADICALE_HTPASSWD_FILENAME:-/etc/radicale/users}"
CONFIG_FILE="${RADICALE_CONFIG:-/etc/radicale/config}"
PASSWORD="${RADICALE_PASSWORD:-${RADICALE_PASS:-}}"

if [ -n "${RADICALE_USER:-}" ] || [ -n "${PASSWORD}" ]; then
    if [ -z "${RADICALE_USER:-}" ] || [ -z "${PASSWORD}" ]; then
        echo "docker-entrypoint: RADICALE_USER and RADICALE_PASSWORD (or RADICALE_PASS) must both be set" >&2
        exit 1
    fi
    if [ ! -f "${HTPASSWD_FILE}" ]; then
        mkdir -p "$(dirname "${HTPASSWD_FILE}")"
        htpasswd -B -b -c "${HTPASSWD_FILE}" "${RADICALE_USER}" "${PASSWORD}"
        chown radicale:radicale "${HTPASSWD_FILE}"
        chmod 640 "${HTPASSWD_FILE}"
    fi
    if [ ! -f "${CONFIG_FILE}" ]; then
        mkdir -p "$(dirname "${CONFIG_FILE}")"
        {
            echo "[auth]"
            echo "type = htpasswd"
            echo "htpasswd_filename = ${HTPASSWD_FILE}"
            echo "htpasswd_encryption = autodetect"
        } > "${CONFIG_FILE}"
        chown radicale:radicale "${CONFIG_FILE}"
        chmod 640 "${CONFIG_FILE}"
    fi
    unset PASSWORD RADICALE_PASSWORD RADICALE_PASS
fi

exec su-exec radicale /app/bin/python /app/bin/radicale "$@"
