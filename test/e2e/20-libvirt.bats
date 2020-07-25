#!/usr/bin/env bats

@test "Wait for ready" {
    wait-for 1 30 virsh connect
}
