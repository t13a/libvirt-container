#!/usr/bin/env bats

@test "Generate key" {
    SSH_SECRET_KEY=~/.ssh/id_rsa

    if [ -f "${SSH_SECRET_KEY}" ]
    then
        skip "Already exists"
    fi

    ssh-keygen -q -f "${SSH_SECRET_KEY}" -t rsa -N ''
}

@test "Generate config" {
    SSH_CONFIG=~/.ssh/config

    if [ -f "${SSH_CONFIG}" ]
    then
        skip "Already exists"
    fi

    eval-template < "${TEMPLATE_DIR}/ssh-config.template" > "${SSH_CONFIG}"
    chmod 644 "${SSH_CONFIG}"
}

@test "Wait for port open" {
    wait-for 1 30 nc -vz "${LIBVIRT_HOST}" 22
}

@test "Verify password authentication" {
    timeout 10 sshpass -e ssh -o PreferredAuthentications=password "${LIBVIRT_HOST}" true
}

@test "Push SSH authorized keys" {
    sshpass -e push-ssh-authorized-keys
}

@test "Verify public key authentication" {
    timeout 10 ssh -o PreferredAuthentications=publickey "${LIBVIRT_HOST}" true
}
