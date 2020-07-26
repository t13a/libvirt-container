# Libvirt container

[![Build Status](https://travis-ci.org/t13a/dockerfile-libvirt.svg?branch=master)](https://travis-ci.org/t13a/dockerfile-libvirt)

A containerized [Libvirt](https://libvirt.org/), disposable virtualization infrastructure intended for development. **Do not use for production**.

- Based on [the official image of CentOS 7](https://hub.docker.com/_/centos)
- Use [Supervisor](http://supervisord.org/) instead of [Systemd](https://freedesktop.org/wiki/Software/systemd/)
- Use [KVM](https://www.linux-kvm.org/page/Main_Page) if available
- Connect via SSH

## Getting started

### Prerequisites

- Bash
- Docker Compose
- GNU Make
- OpenSSH

### Setup

Currently, SSH is the only way to communicate with the container. Public key authentication and password authentication are available. By default, the valid public key is assumed to be in `~/.ssh/id_rsa.pub`. If so, setup the container is very easy.

```bash
$ make all up # equivalent to `make build up`
```

To specify another location, override `SSH_AUTHORIZED_KEYS` environment variable.

```bash
$ make SSH_AUTHORIZED_KEYS="$(cat path/to/public-key)" all up
```

If you don't have or wan't to use your public key, You can disable public key authentication and enable password authentication.

```bash
$ make LIBVIRT_USER_PASSWORD='password' SSH_AUTHORIZED_KEYS='' all up
```

### Connect to Libvirt

There are several ways to connect to Libvirt. The simplest way is to login via SSH and run virsh (Libvirt management CLI).

```bash
$ ssh -p 2222 libvirt-user@127.0.0.1 virsh --connect=qemu:///system
```

Or, if virsh is installed on your computer, the following command is equivalent to the above.

```bash
$ virsh --connect=qemu+ssh://libvirt-user@127.0.0.1:2222/system
```

### Teardown

To stop the container, execute the following command.

```bash
$ make down
```

You can return to the previous state by executing `make up` command again.

To erase everything including Docker image and volumes, execute the following command.

```bash
$ make clean
```

## Development

### E2E Test

We will actually provision an [Ubuntu 20.04 LTS (Focal Fossa)](https://cloud-images.ubuntu.com/focal/) instance and login via SSH.

```bash
$ make test
```
