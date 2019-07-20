#!/bin/bash

set -euo pipefail

function populate_dir() {
    if mountpoint "${1}" > /dev/null
    then
        cp -anv "/mnt${1}"/* "${1}"
    fi
}

groupadd -g "${SSH_GID}" "${SSH_USER}"
useradd -d "/home/${SSH_USER}" -g "${SSH_GID}" -M -u "${SSH_UID}" -s /bin/bash "${SSH_USER}"
gpasswd -a "${SSH_USER}" libvirt
echo "${SSH_USER} ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/${SSH_USER}"

mount -B --make-private / /mnt
populate_dir /etc/ssh
populate_dir /etc/libvirt
populate_dir /var/lib/libvirt
umount /mnt

if [ ${#@} -eq 0 ]
then
    exec /usr/sbin/init
else
    exec "${@}"
fi
