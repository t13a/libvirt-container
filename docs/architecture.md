# Architecture Overview

## Purpose

Libvirt-container provides a containerized [Libvirt](https://libvirt.org/) environment for disposable virtualization infrastructure intended for development use. It allows developers to run KVM-based virtual machines inside a Docker container without installing libvirt on the host system.

**This project is not intended for production use.**

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ Host Machine                                                │
│                                                             │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Docker Container (privileged)                          │ │
│  │                                                        │ │
│  │  SystemD (PID 1)                                       │ │
│  │    ├── libvirt daemon + related services                │ │
│  │    ├── SSH server                                      │ │
│  │    └── ...                                             │ │
│  │                                                        │ │
│  │  ┌──────────────────────────────────────────────────┐  │ │
│  │  │ Guest VM (QEMU/KVM)                              │  │ │
│  │  │  - Managed by libvirt                            │  │ │
│  │  │  - NAT networking via virtual bridge             │  │ │
│  │  │  - Accessible via SSH (ProxyJump through host)   │  │ │
│  │  └──────────────────────────────────────────────────┘  │ │
│  │                                                        │ │
│  └──────────────────┬─────────────────────────────────────┘ │
│                     │                                       │
│              Port mapping                                   │
│          (host:2222 → container:22)                         │
│                     │                                       │
│              /dev/kvm (if available)                         │
└─────────────────────────────────────────────────────────────┘
```

## Tech Stack

| Component        | Technology                                        |
|------------------|---------------------------------------------------|
| Base image       | Debian 13 (trixie)                                |
| Init system      | SystemD                                           |
| Hypervisor       | QEMU/KVM (falls back to QEMU emulation if no KVM) |
| VM management    | Libvirt (Debian 13 official packages)             |
| Remote access    | OpenSSH server                                    |
| Container engine | Docker with Docker Compose                        |
| Build tool       | GNU Make                                          |
| Test framework   | Ansible + Molecule                                |

## User Interface

The container is accessed exclusively via SSH. There are two ways to interact with libvirt:

1. **SSH login + virsh**: Log into the container via SSH and run virsh commands directly.

   ```
   ssh -p 2222 libvirt-user@127.0.0.1 virsh --connect=qemu:///system list --all
   ```

2. **Remote libvirt URI**: Use the `qemu+ssh://` URI scheme to connect from the host without an interactive SSH session.

   ```
   virsh --connect=qemu+ssh://libvirt-user@127.0.0.1:2222/system list --all
   ```

Guest VMs running inside the container can be reached via SSH using `ProxyJump` through the container:

```
ssh -J libvirt-user@127.0.0.1:2222 guest-user@<guest-ip>
```

## Lifecycle Management

The container lifecycle is managed via Docker Compose and GNU Make:

| Operation      | Command       | Description                                       |
|----------------|---------------|---------------------------------------------------|
| Build image    | `make build`  | Build the Docker image                            |
| Start          | `make up`     | Start the container in the background             |
| Stop           | `make down`   | Stop the container (preserves volumes)            |
| Shell access   | `make exec`   | Open an interactive shell inside the container    |
| Run tests      | `make test`   | Execute the E2E test suite                        |
| Full cleanup   | `make clean`  | Remove images, containers, and volumes            |

## Authentication

Two authentication methods are supported for SSH access:

- **Public key authentication**: SSH public keys are injected via the `SSH_AUTHORIZED_KEYS` environment variable at container startup.
- **Password authentication**: Enabled when the `LIBVIRT_USER_PASSWORD` environment variable is set.

Both methods can be used simultaneously.

## License

GPL v2
