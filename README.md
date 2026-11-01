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
| `test-clean` | Remove the containers, images, and volumes of the test |
| `clean`  | Remove images, containers, and volumes         |

## Environment Variables

| Variable                | Default   | Description                                            |
|-------------------------|-----------|--------------------------------------------------------|
| `LIBVIRT_USER_PASSWORD` | _(unset)_ | If set, sets the password of `libvirt-user`            |
| `SSH_AUTHORIZED_KEYS`   | _(unset)_ | If set, installs SSH public key(s) for `libvirt-user`  |
| `SSH_PORT`              | `2222`    | Host port mapped to container SSH (port 22)            |

By default, `SSH_AUTHORIZED_KEYS` is populated from `~/.ssh/id_rsa.pub` when using the Makefile. The container installs the keys each time it starts, so start it with `make up`: `docker compose up` alone passes no keys, and the container then accepts only a password.

## Authentication

Two methods are supported for SSH access:

- **Public key authentication**: SSH public keys are injected via `SSH_AUTHORIZED_KEYS` at container startup.
- **Password authentication**: Enabled when `LIBVIRT_USER_PASSWORD` is set.

Both methods can be used simultaneously.

## Volumes

Named volumes keep what should survive `make down`, which `make clean` deletes:

| Mount point        | Holds                                                    |
|--------------------|----------------------------------------------------------|
| `/etc/libvirt`     | The configuration of libvirt                             |
| `/var/lib/libvirt` | VM disk images, network definitions, and other state     |
| `/etc/ssh`         | The SSH host keys, so the container keeps its host key   |

## Accessing Guest VMs

Guest VMs running inside the container can be reached via SSH using `ProxyJump`:

```bash
ssh -J libvirt-user@127.0.0.1:2222 guest-user@<guest-ip>
```

## Published Image

Each release publishes the image to `ghcr.io/t13a/libvirt-container`, under its version, such as `0.1.0`, and as `latest`. To run it without this repository, give `docker run` what `docker-compose.yml` gives:

```bash
docker run -d --name libvirt --privileged --security-opt apparmor=unconfined -p 2222:22 \
  -v libvirt_conf:/etc/libvirt -v libvirt_data:/var/lib/libvirt -v ssh_conf:/etc/ssh \
  -e SSH_AUTHORIZED_KEYS="$(cat ~/.ssh/id_rsa.pub)" \
  ghcr.io/t13a/libvirt-container
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

## Development

[AGENTS.md](AGENTS.md) describes how the container works, and how to develop and test it.
