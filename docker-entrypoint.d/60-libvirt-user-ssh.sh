#!/bin/bash
set -e

USER="${LIBVIRT_USER:-libvirt-user}"

# Install SSH authorized keys only if SSH_AUTHORIZED_KEYS is set
if [ -n "$SSH_AUTHORIZED_KEYS" ]; then
    HOME_DIR=$(eval echo "~$USER")
    mkdir -p "$HOME_DIR/.ssh"
    chmod 700 "$HOME_DIR/.ssh"
    echo "$SSH_AUTHORIZED_KEYS" > "$HOME_DIR/.ssh/authorized_keys"
    chmod 600 "$HOME_DIR/.ssh/authorized_keys"
    chown -R "$USER:" "$HOME_DIR/.ssh"
fi
