#!/bin/bash
set -e

USER="${LIBVIRT_USER:-libvirt-user}"
USER_UID="${LIBVIRT_USER_UID:-1000}"
USER_GID="${LIBVIRT_USER_GID:-1000}"

# Create group if it does not exist
if ! getent group "$USER" &>/dev/null; then
    groupadd --gid "$USER_GID" "$USER"
fi

# Create user if it does not exist
if ! id "$USER" &>/dev/null; then
    useradd --uid "$USER_UID" --gid "$USER_GID" --create-home --shell /bin/bash "$USER"
fi

# Add to libvirt group
usermod -aG libvirt "$USER"
