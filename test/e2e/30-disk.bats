#!/usr/bin/env bats

@test "Create virtual disk (${DISTRO_NAME})" {
    if distro-image-exists
    then
        skip "already exists"
    fi

    push-distro-image
}

@test "Create virtual disk (root filesystem)" {
    if rootfs-image-exists
    then
        skip "already exists"
    fi

    create-rootfs-image
}

@test "Create virtual disk (cloud-init data source)" {
    if cidata-image-exists
    then
        skip "already exists"
    fi

    push-cidata-image
}
