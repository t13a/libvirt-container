#!/usr/bin/env bash

set -euo pipefail

! id healthcheck > /dev/null 2>&1 || exit 0

useradd -d /var/local/healthcheck -m -r -s /bin/bash healthcheck
gpasswd -a healthcheck libvirt

su healthcheck -c 'ssh-keygen -q -C healthcheck -f ~/.ssh/id_rsa -t rsa -N ""'
su healthcheck -c 'cp ~/.ssh/{id_rsa.pub,authorized_keys}'
su healthcheck -c 'cat - > ~/.ssh/config' << EOF
Host 127.0.0.1
    StrictHostKeyChecking no
EOF

su healthcheck -c 'mkdir -p ~/.config/libvirt'
su healthcheck -c 'cat - > ~/.config/libvirt/libvirt.conf' << EOF
uri_default = "qemu+ssh://127.0.0.1/system"
EOF
