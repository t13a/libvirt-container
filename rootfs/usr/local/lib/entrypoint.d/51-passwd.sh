#!/usr/bin/env bash

set -euo pipefail

[ -n "${LIBVIRT_USER_PASSWORD:-}" ] || exit 0

passwd --stdin "${LIBVIRT_USER}" <<< "${LIBVIRT_USER_PASSWORD}"
