#!/usr/bin/env bats

load /opt/bats-assert/load.bash
load /opt/bats-support/load.bash

@test "Define domain" {
    setup-machine
}

@test "Enable domain autostart" {
    virsh autostart "${DOMAIN_NAME}"
}

@test "Start domain" {
    if virsh list --name | grep -q "^${DOMAIN_NAME}$"
    then
        skip "Domain '${DOMAIN_NAME}' already started"
    fi

    run domain-wait-for-login-prompt
    echo "${output}" > /tmp/domain.log
    assert_success
}

@test "Connect domain via SSH" {
    run wait-for 1 30 ssh "${DOMAIN_NAME}" true
    assert_success || fail "$(cat /tmp/domain.log)"
}

@test "Print boot log" {
    run wait-for 1 30 ssh "${DOMAIN_NAME}" true
    diag cat /tmp/domain.log
}
