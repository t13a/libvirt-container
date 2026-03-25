#!/bin/bash
set -e

USER="${LIBVIRT_USER:-libvirt-user}"

# Grant passwordless sudo
echo "$USER ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/$USER"
chmod 440 "/etc/sudoers.d/$USER"
