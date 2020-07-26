#!/usr/bin/env bats

load /opt/bats-assert/load.bash
load /opt/bats-support/load.bash

@test "Create virtual machine" {
    setup-machine
}

@test "Set autostart" {
    virsh autostart "${MACHINE_NAME}"
}

@test "Start virtual machine" {
    if virsh list --name | grep -q "^${MACHINE_NAME}$"
    then
        skip "Domain '${MACHINE_NAME}' already started"
    fi

    run domain-wait-for-login-prompt
    echo "${output}" > /tmp/domain.log
    assert_success
}

@test "Connect via SSH" {
    run wait-for 1 30 ssh "${MACHINE_NAME}" true
    assert_success || fail "$(cat /tmp/domain.log)"
}

@test "Print boot log" {
    run wait-for 1 30 ssh "${MACHINE_NAME}" true
    diag cat /tmp/domain.log
}
