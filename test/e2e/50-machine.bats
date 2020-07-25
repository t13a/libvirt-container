#!/usr/bin/env bats

@test "Create virtual machine" {
    setup-machine
}

@test "Wait for boot" {
    wait-for-boot
}

@test "Connect via SSH" {
    wait-for 1 30 ssh "${MACHINE_NAME}" true
}
