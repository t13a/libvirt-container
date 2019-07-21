#!/bin/bash

set -euxo pipefail

function cmd_fetch_ubuntu() {
    sudo curl -L "${UBUNTU_QCOW2_URL}" -o "${UBUNTU_QCOW2}"
}

function cmd_gen_disk() {
    sudo qemu-img create -f qcow2 -b "${UBUNTU_QCOW2}" "${DISK_QCOW2}"
}

function cmd_gen_cidata() {
    cat << EOF > "${CIDATA_META_DATA}"
instance-id: ${MACHINE_NAME}
local-hostname: ${MACHINE_NAME}
EOF
    cat << EOF > "${CIDATA_NETWORK_CONFIG}"
network:
  version: 1
  config:
  - type: physical
    name: eth0
    mac_address: '${MACHINE_MAC}'
    subnets:
    - type: static
      address: '${MACHINE_ADDRESS}/${NETWORK_MASK}'
      gateway: '${NETWORK_ADDRESS}'
      dns_nameservers:
      - '${NETWORK_ADDRESS}'
EOF
    cat << EOF > "${CIDATA_USER_DATA}"
#cloud-config

ssh_authorized_keys:
- '$(cat "${SSH_KEY_PUB}")'
EOF
    sudo genisoimage \
        -output "${CIDATA_ISO}" \
        -volid cidata \
        -joliet \
        -rock \
        "${CIDATA_META_DATA}" \
        "${CIDATA_NETWORK_CONFIG}" \
        "${CIDATA_USER_DATA}"
}

function cmd_create_network() {
    cat << EOF > "${NETWORK_XML}"
<network>
  <name>${NETWORK_NAME}</name>
  <bridge name="${NETWORK_BRIDGE_NAME}"/>
  <forward mode="nat"/>
  <ip address="${NETWORK_ADDRESS}" netmask="${NETWORK_MASK_ADDRESS}"/>
</network>
EOF
    virsh --connect qemu:///system net-create "${NETWORK_XML}"
}

function cmd_create_machine() {
    local cmd_args=(
        virt-install
        --connect qemu:///system
        --name "${MACHINE_NAME}"
        --memory "${MACHINE_MEMORY}"
        --vcpus 1
        --os-type linux
        --boot hd
        --disk path="${DISK_QCOW2}",format=qcow2
        --disk path="${CIDATA_ISO}",perms=ro
        --network bridge="${NETWORK_BRIDGE_NAME}",mac="${MACHINE_MAC}"
        --graphics none
        --noautoconsole
    )

    if [ -e /dev/kvm ]
    then
        cmd_args+=(
            --cpu host
            --os-variant virtio26
        )
    fi

    "${cmd_args[@]}"
}

function cmd_wait_login_prompt() {
    expect << EOF

set timeout ${TIMEOUT_SECS}

spawn virsh --connect=qemu:///system console ${MACHINE_NAME}

expect {
  eof {
    puts "Failed to get console (eof)"
    exit 1
  }
  timeout {
    puts "Failed to get console (timeout)"
    exit 1
  }
  "Escape character is ^]"
}

send "\n"

expect {
  eof {
    puts "Failed to get login prompt (eof)"
    exit 1
  }
  timeout {
    puts "Failed to get login prompt (timeout)"
    exit 1
  }
  "${MACHINE_NAME} login:"
}

puts "Passed"
EOF
}

function cmd_connect_via_ssh() {
    ssh \
        -i "${SSH_KEY}" \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        "ubuntu@${MACHINE_ADDRESS}" \
        cat /etc/os-release
}

NETWORK_NAME=default
NETWORK_BRIDGE_NAME=virtbr0
NETWORK_ADDRESS=192.168.122.1
NETWORK_MASK=24
NETWORK_MASK_ADDRESS=255.255.255.0
NETWORK_XML="${HOME}/${NETWORK_NAME}.xml"

MACHINE_NAME=ubuntu
MACHINE_MEMORY=512
MACHINE_MAC=52:54:00:12:34:56
MACHINE_ADDRESS=192.168.122.2

UBUNTU_QCOW2_URL=https://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img
UBUNTU_QCOW2="/var/lib/libvirt/images/$(basename "${UBUNTU_QCOW2_URL}")"

DISK_QCOW2="/var/lib/libvirt/images/${MACHINE_NAME}.qcow2"

SSH_KEY="${HOME}/id_rsa"
SSH_KEY_PUB="${HOME}/id_rsa.pub"

CIDATA_META_DATA="${HOME}/meta-data"
CIDATA_NETWORK_CONFIG="${HOME}/network-config"
CIDATA_USER_DATA="${HOME}/user-data"
CIDATA_ISO=/var/lib/libvirt/images/cidata.iso

for CMD in "${@}"
do
    "cmd_${CMD//-/_}"
done
