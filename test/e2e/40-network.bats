#!/usr/bin/env bats

@test "Define network" {
    if network-is-defined
    then
        skip "already defined"
    fi

    define-network
}

@test "Enable network autostart" {
    virsh net-autostart "${NETWORK_NAME}"
}

@test "Start network" {
    if network-is-active
    then
        skip "already started"
    fi

    start-network
}
