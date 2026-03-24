# libvirt-container

Containerized [Libvirt](https://libvirt.org/) environment for disposable virtualization infrastructure. Run KVM-based virtual machines inside a Docker container without installing libvirt on the host system.

**This project is intended for development use only.**

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

## Quick Start

```bash
# Build the image
make build

# Start the container (with SSH public key authentication)
make up

# Or with password authentication
LIBVIRT_USER_PASSWORD=mypassword make up

# Access the container
ssh -p 2222 libvirt-user@127.0.0.1

# Use virsh remotely
virsh --connect=qemu+ssh://libvirt-user@127.0.0.1:2222/system list --all

# Stop the container
make down
```

## Requirements

- Docker with Docker Compose
- `/dev/kvm` for hardware acceleration (optional; falls back to QEMU emulation)

## Make Targets

| Target   | Description                                    |
|----------|------------------------------------------------|
| `build`  | Build the Docker image                         |
| `up`     | Start the container in the background          |
| `down`   | Stop the container (preserves volumes)         |
| `exec`   | Open an interactive shell inside the container |
| `test`   | Run the E2E test suite                         |
| `clean`  | Remove images, containers, and volumes         |

## Environment Variables

| Variable               | Default        | Description                                     |
|------------------------|----------------|-------------------------------------------------|
| `LIBVIRT_USER`         | `libvirt-user` | Application user name                           |
| `LIBVIRT_USER_UID`     | `1000`         | Application user UID                            |
| `LIBVIRT_USER_GID`     | `1000`         | Application user GID                            |
| `LIBVIRT_USER_PASSWORD` | _(unset)_     | If set, configures the user's password          |
| `SSH_AUTHORIZED_KEYS`   | _(unset)_     | If set, installs SSH public key(s) for the user |
| `SSH_PORT`             | `2222`         | Host port mapped to container SSH (port 22)     |

By default, `SSH_AUTHORIZED_KEYS` is populated from `~/.ssh/id_rsa.pub` when using the Makefile.

## Authentication

Two methods are supported for SSH access:

- **Public key authentication**: SSH public keys are injected via `SSH_AUTHORIZED_KEYS` at container startup.
- **Password authentication**: Enabled when `LIBVIRT_USER_PASSWORD` is set.

Both methods can be used simultaneously.

## Accessing Guest VMs

Guest VMs running inside the container can be reached via SSH using `ProxyJump`:

```bash
ssh -J libvirt-user@127.0.0.1:2222 guest-user@<guest-ip>
```

## Tech Stack

| Component        | Technology                                         |
|------------------|----------------------------------------------------|
| Base image       | Debian 13 (trixie)                                 |
| Init system      | SystemD                                            |
| Hypervisor       | QEMU/KVM (falls back to QEMU emulation if no KVM) |
| VM management    | Libvirt (Debian 13 official packages)              |
| Remote access    | OpenSSH server                                     |
| Container engine | Docker with Docker Compose                         |
| Build tool       | GNU Make                                           |
| Test framework   | Ansible + Molecule                                 |

## Documentation

- [Architecture Overview](docs/architecture.md)
- [Container Image Specification](docs/container-spec.md)
- [Test Specification](docs/test-spec.md)
- [Implementation Plan](docs/implementation-plan.md)

## License

GPL v2
