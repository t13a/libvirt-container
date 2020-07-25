#!/usr/bin/env bash

set -euo pipefail

if ! getent group "${LIBVIRT_USER}" > /dev/null
then
    groupadd -g "${LIBVIRT_USER_GID}" "${LIBVIRT_USER}"
fi

if ! getent passwd "${LIBVIRT_USER}" > /dev/null
then
    useradd -g "${LIBVIRT_USER_GID}" -m -u "${LIBVIRT_USER_UID}" -s /bin/bash "${LIBVIRT_USER}"
    gpasswd -a "${LIBVIRT_USER}" libvirt
fi
