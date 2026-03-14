#!/usr/bin/env bash

set -euo pipefail

[ -n "${LIBVIRT_USER_PASSWORD:-}" ] || exit 0

echo "${LIBVIRT_USER}:${LIBVIRT_USER_PASSWORD}" | chpasswd
