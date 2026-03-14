#!/usr/bin/env bash

set -euo pipefail

! id healthcheck > /dev/null 2>&1 || exit 0

useradd -d /var/local/healthcheck -m -r -s /bin/bash healthcheck
gpasswd -a healthcheck libvirt

su healthcheck -c 'mkdir -p ~/.config/libvirt'
su healthcheck -c 'cat - > ~/.config/libvirt/libvirt.conf' << 'EOF'
uri_default = "qemu:///system"
EOF
