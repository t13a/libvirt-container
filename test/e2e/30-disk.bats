#!/usr/bin/env bats

@test "Create virtual disk (Ubuntu)" {
    setup-disk.ubuntu
}

@test "Create virtual disk (root filesystem)" {
    setup-disk.rootfs
}

@test "Create virtual disk (cloud-init)" {
    setup-disk.cidata
}
