#!/usr/bin/env bats

@test "Create virtual network" {
    setup-network
}

@test "Set autostart" {
    virsh net-autostart "${NETWORK_NAME}"
}

@test "Start virtual network" {
    if virsh net-list --name | grep -q "^${NETWORK_NAME}$"
    then
        skip "Network '${NETWORK_NAME}' already started"
    fi

    virsh net-start "${NETWORK_NAME}"
}

@test "Print hypervisor's addresses" {
    diag ssh "${LIBVIRT_HOST}" /sbin/ip address
}

@test "Print hypervisor's routing table" {
    diag ssh "${LIBVIRT_HOST}" /sbin/ip route
}
