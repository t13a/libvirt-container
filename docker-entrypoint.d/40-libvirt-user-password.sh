#!/bin/bash
set -e

USER="${LIBVIRT_USER:-libvirt-user}"

# Set password only if LIBVIRT_USER_PASSWORD is set
if [ -n "$LIBVIRT_USER_PASSWORD" ]; then
    echo "$USER:$LIBVIRT_USER_PASSWORD" | chpasswd
fi
