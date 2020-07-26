#!/usr/bin/env bats

load /opt/bats-assert/load.bash
load /opt/bats-support/load.bash

@test "Define domain" {
    if domain-is-defined
    then
        skip "already defined"
    fi

    define-domain
}

@test "Enable domain autostart" {
    virsh autostart "${DOMAIN_NAME}"
}

@test "Start domain" {
    if domain-is-active
    then
        skip "already started"
    fi

    run wait-for-login-prompt
    echo "${output}" > /tmp/domain.log
    assert_success
}

@test "Connect domain via SSH" {
    run wait-for 1 30 ssh "${DOMAIN_NAME}" true
    assert_success || fail "$(cat /tmp/domain.log)"
}
