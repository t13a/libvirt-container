# Libvirt

[![Build Status](https://travis-ci.org/t13a/dockerfile-libvirt.svg?branch=master)](https://travis-ci.org/t13a/dockerfile-libvirt)

A Dockerfile for [Libvirt](https://libvirt.org/). A disposable virtualization infrastructure intended for development. **Do not use for production**.

- Based on the [official build of CentOS](https://hub.docker.com/_/centos)
- Use [Supervisor](http://supervisord.org/) instead of [Systemd](https://freedesktop.org/wiki/Software/systemd/)
- Use [KVM](https://www.linux-kvm.org/page/Main_Page) if available
- Connect via SSH

## Prerequisites

- Docker Compose 1.13+
- GNU Make
- KVM enabled Linux (optional)
- OpenSSH

## Getting started

### Setup

Currently, SSH is the only way to communicate with the container. Password authentication can not be used. Please prepare a valid SSH key in advance. By default, the valid SSH public key is assumed to be in `~/.ssh/id_rsa.pub`. If so, setup the container is very easy.

```bash
$ make up
```

To specify another location, override `SSH_AUTHORIZED_KEYS` environment variable.

```bash
$ make SSH_AUTHORiZED_KEYS="$(cat path/to/pub-key)" up
```


### Connect to Libvirt

There are several ways to connect to Libvirt. The simplest way is to login via SSH and run virsh (Libvirt management CLI).

```bash
$ ssh -p 2222 127.0.0.1 virsh --connect=qemu:///system
```

Or, if virsh is installed on your computer, the following command is equivalent to the above.

```bash
$ virsh --connect=qemu+ssh://127.0.0.1:2222/system
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

### Test

We will actually provision an [Ubuntu 16.04 LTS (Xenial Xerus)](https://cloud-images.ubuntu.com/xenial/) instance and login via SSH.

```bash
$ make all test
```
