# Container Image Specification

## Base Image

`debian:trixie` (Debian 13, full image — not slim, as the container is development-oriented)

## Required Packages

Install from Debian 13 official repositories:

| Package                | Purpose                            |
|------------------------|------------------------------------|
| libvirt-daemon-system  | Libvirt daemon with system integration |
| qemu-system-x86        | QEMU emulator for x86_64           |
| openssh-server         | SSH server for remote access        |
| sudo                   | Privilege escalation for users      |
| virt-install           | VM provisioning tool                |
| libvirt-clients        | virsh and other client tools        |
| qemu-utils             | qemu-img and other utilities        |

Service configuration is handled by the standard Debian package installation procedures. Do not manually configure individual SystemD units beyond what the packages provide.

## Init System

SystemD runs as PID 1 inside the container. All services (libvirt, SSH, etc.) are managed through standard SystemD integration provided by the installed Debian packages.

## Libvirt Configuration

Polkit authorization must be disabled because logind is not available inside the container:

```
# /etc/libvirt/libvirtd.conf
access_drivers = [ "none" ]
```

## Initialization

The following initialization steps must be performed at container startup (before or as SystemD oneshot units). The steps are executed in the order listed.

### 1. SSH Host Key Generation

Generate SSH host keys if they do not already exist:

```
ssh-keygen -A
```

This is idempotent — existing keys in `/etc/ssh` (persisted via volume) are preserved.

### 2. Healthcheck User

Create a system user dedicated to health checking:

- User name: `healthcheck`
- Added to the `libvirt` group
- Has an SSH keypair generated in its home directory
- Has an SSH config pointing to `127.0.0.1`
- Has a libvirt URI configured: `qemu+ssh://127.0.0.1/system`

This user verifies that libvirt is operational without requiring root privileges.

### 3. Application User

Create the main application user for libvirt management:

- User name: value of `LIBVIRT_USER` (default: `libvirt-user`)
- UID: value of `LIBVIRT_USER_UID` (default: `1000`)
- GID: value of `LIBVIRT_USER_GID` (default: `1000`)
- Added to the `libvirt` group (grants access to libvirt socket)
- Home directory created

### 4. Password Setting (Conditional)

If the `LIBVIRT_USER_PASSWORD` environment variable is set:

- Set the application user's password to the specified value

If unset, password authentication remains disabled for this user.

### 5. Sudo Configuration

Grant the application user passwordless sudo privileges:

```
<username> ALL=(ALL) NOPASSWD: ALL
```

### 6. SSH Authorized Keys (Conditional)

If the `SSH_AUTHORIZED_KEYS` environment variable is set:

- Create `~/.ssh` directory with mode `700`
- Write the value to `~/.ssh/authorized_keys` with mode `600`
- Set ownership to the application user

If unset, public key authentication is not configured (password auth or other methods must be used).

## Environment Variables

| Variable                | Default         | Description                                    |
|-------------------------|-----------------|------------------------------------------------|
| `LIBVIRT_USER`          | `libvirt-user`  | Application user name                          |
| `LIBVIRT_USER_UID`      | `1000`          | Application user UID                           |
| `LIBVIRT_USER_GID`      | `1000`          | Application user GID                           |
| `LIBVIRT_USER_PASSWORD`  | _(unset)_       | If set, configures the user's password         |
| `SSH_AUTHORIZED_KEYS`    | _(unset)_       | If set, installs SSH public key(s) for the user |

## Health Check

The container health check verifies libvirt connectivity by running:

```
su healthcheck -c 'virsh connect'
```

- Exit code `0`: healthy (libvirt is responsive)
- Non-zero exit code: unhealthy

This check uses the dedicated `healthcheck` user (non-root) to confirm that unprivileged users can access libvirt through the configured connection URI.

## Runtime Requirements

### Privileges

The container requires elevated privileges for KVM virtualization:

```yaml
privileged: true
security_opt:
  - apparmor=unconfined
```

### KVM Device

- If `/dev/kvm` is available on the host, KVM hardware acceleration is used
- If `/dev/kvm` is not available, QEMU falls back to software emulation (significantly slower)

### Persistent Volumes

Named Docker volumes provide persistence across container restarts:

| Mount Point       | Purpose                                      |
|-------------------|----------------------------------------------|
| `/etc/libvirt`    | Libvirt daemon configuration                 |
| `/var/lib/libvirt` | VM disk images, network definitions, state   |
| `/etc/ssh`        | SSH host keys (preserves host identity)       |

### Port Mapping

| Host Port           | Container Port | Protocol | Purpose         |
|---------------------|----------------|----------|-----------------|
| Configurable (2222) | 22             | TCP      | SSH access       |

## Docker Compose Configuration

The `docker-compose.yml` defines a single service:

```yaml
services:
  libvirt:
    build: .
    privileged: true
    security_opt:
      - apparmor=unconfined
    ports:
      - "${SSH_PORT:-2222}:22"
    volumes:
      - libvirt_conf:/etc/libvirt
      - libvirt_data:/var/lib/libvirt
      - ssh_conf:/etc/ssh
    environment:
      - LIBVIRT_USER_PASSWORD
      - SSH_AUTHORIZED_KEYS

volumes:
  libvirt_conf:
  libvirt_data:
  ssh_conf:
```

## Makefile

The top-level `Makefile` provides convenience targets:

| Target   | Description                                               |
|----------|-----------------------------------------------------------|
| `build`  | Build the Docker image                                    |
| `up`     | Start the container (`docker compose up -d`)               |
| `down`   | Stop the container (`docker compose down`)                 |
| `exec`   | Open a shell as the application user                       |
| `clean`  | Remove images, containers, and volumes                     |
| `test`   | Run the E2E test suite                                     |
| `all`    | Default target — alias for `build`                         |

The `SSH_AUTHORIZED_KEYS` variable should default to reading `~/.ssh/id_rsa.pub` when available.
