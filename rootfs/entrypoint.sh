#!/bin/bash

set -euo pipefail

function populate_dir() {
    if mountpoint "${1}" > /dev/null
    then
        cp -anv "/mnt${1}"/* "${1}"
    fi
}

if ! getent group "${SSH_USER}" > /dev/null
then
    groupadd -g "${SSH_GID}" "${SSH_USER}"
fi

if ! getent passwd "${SSH_USER}" > /dev/null
then
    useradd -g "${SSH_GID}" -m -u "${SSH_UID}" -s /bin/bash "${SSH_USER}"
    gpasswd -a "${SSH_USER}" libvirt
    echo "${SSH_USER} ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/${SSH_USER}"
fi

if [ -n "${SSH_AUTHORIZED_KEYS:-}" ]
then
    sudo -u "${SSH_USER}" bash << EOF
mkdir ~/.ssh \\
&& echo "${SSH_AUTHORIZED_KEYS}" > ~/.ssh/authorized_keys
EOF
fi

mount -B --make-private / /mnt
populate_dir /etc/ssh
populate_dir /etc/libvirt
populate_dir /var/lib/libvirt
umount /mnt

if [ ! -e /etc/ssh/ssh_host_dsa_key \
    -o ! -e /etc/ssh/ssh_host_dsa_key.pub \
    -o ! -e /etc/ssh/ssh_host_ecdsa_key \
    -o ! -e /etc/ssh/ssh_host_ecdsa_key.pub \
    -o ! -e /etc/ssh/ssh_host_ed25519_key \
    -o ! -e /etc/ssh/ssh_host_ed25519_key.pub \
    -o ! -e /etc/ssh/ssh_host_key \
    -o ! -e /etc/ssh/ssh_host_key.pub \
    -o ! -e /etc/ssh/ssh_host_rsa_key \
    -o ! -e /etc/ssh/ssh_host_rsa_key.pub ]
then
    ssh-keygen -A
fi

if [ ${#@} -eq 0 ]
then
    exec supervisord
else
    exec "${@}"
fi
