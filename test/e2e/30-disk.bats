#!/usr/bin/env bats

@test "Create virtual disk (${DISTRO_NAME})" {
    setup-disk.distro
}

@test "Create virtual disk (root filesystem)" {
    setup-disk.rootfs
}

@test "Create virtual disk (cloud-init)" {
    setup-disk.cidata
}
