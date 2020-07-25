#!/usr/bin/env bash

set -euo pipefail

echo "${LIBVIRT_USER} ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/${LIBVIRT_USER}"
