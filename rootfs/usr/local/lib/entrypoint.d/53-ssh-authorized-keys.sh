#!/usr/bin/env bash

set -euo pipefail

[ -n "${SSH_AUTHORIZED_KEYS:-}" ] || exit 0

su "${LIBVIRT_USER}" -c 'mkdir -m 755 -p ~/.ssh'
su "${LIBVIRT_USER}" -c 'echo "${SSH_AUTHORIZED_KEYS}" > ~/.ssh/authorized_keys'
