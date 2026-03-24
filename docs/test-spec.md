# Test Specification

## Framework

Tests use **Ansible + Molecule** for end-to-end testing of the containerized libvirt environment.

This replaces the previous test harness (custom shell scripts + Bats).

## Test VM

The test VM uses a **Debian 13 (trixie) Cloud Image**, provisioned via cloud-init inside the libvirt container.

## Test Environment

The test environment consists of two containers orchestrated by Docker Compose:

1. **Libvirt container** (system under test): The container built from this project, running libvirt with SystemD.
2. **Test runner container**: Executes the Molecule/Ansible test suite against the libvirt container.

The test runner connects to the libvirt container via SSH and manages VMs through `virsh` and related tools.

## E2E Test Scenarios

The following scenarios validate the complete functionality of the libvirt container. Each scenario builds upon the previous ones.

### 1. SSH Connectivity

Verify that the libvirt container is accessible via SSH.

| # | Test Case                        | Expected Result                                              |
|---|----------------------------------|--------------------------------------------------------------|
| 1 | Wait for SSH port                | Port 22 on the libvirt container becomes reachable           |
| 2 | Password authentication          | SSH login with password succeeds                             |
| 3 | Register SSH public key          | Public key is installed in the user's `authorized_keys`      |
| 4 | Public key authentication        | SSH login with public key succeeds                           |

### 2. Libvirt Connectivity

Verify that the libvirt daemon is operational.

| # | Test Case                        | Expected Result                                              |
|---|----------------------------------|--------------------------------------------------------------|
| 1 | Libvirt ready                    | `virsh connect` succeeds (daemon is responsive)              |

### 3. Disk Image Management

Verify that VM disk images can be created and managed.

| # | Test Case                        | Expected Result                                              |
|---|----------------------------------|--------------------------------------------------------------|
| 1 | Download cloud image             | Debian 13 cloud image is downloaded and placed in `/var/lib/libvirt/images/` |
| 2 | Create backing image             | A qcow2 copy-on-write image is created with the cloud image as its backing file |
| 3 | Create cloud-init ISO            | An ISO image containing cloud-init data (meta-data, network-config, user-data) is generated |

### 4. Network Management

Verify that libvirt networking can be configured.

| # | Test Case                        | Expected Result                                              |
|---|----------------------------------|--------------------------------------------------------------|
| 1 | Define NAT network               | A NAT network with DHCP is defined in libvirt                |
| 2 | Enable network autostart         | The network is configured to start automatically             |
| 3 | Start network                    | The network is activated and the virtual bridge is created   |

### 5. VM Domain Management

Verify that a guest VM can be provisioned and accessed.

| # | Test Case                        | Expected Result                                              |
|---|----------------------------------|--------------------------------------------------------------|
| 1 | Define domain                    | A VM domain is defined with the specified resources          |
| 2 | Enable domain autostart          | The domain is configured to start automatically              |
| 3 | Start domain                     | The VM boots and reaches a login prompt                      |
| 4 | SSH to guest VM                  | SSH connection to the guest VM succeeds via `ProxyJump` through the libvirt container |

## Test Parameters

### Network Configuration

| Parameter          | Default Value                |
|--------------------|------------------------------|
| Network name       | `default`                    |
| Bridge name        | `virbr0`                     |
| Network address    | `192.168.122.1`              |
| Netmask            | `255.255.255.0`              |
| DHCP range start   | `192.168.122.128`            |
| DHCP range end     | `192.168.122.254`            |

### Guest VM Specification

| Parameter          | Default Value                |
|--------------------|------------------------------|
| Domain name        | `debian`                     |
| Memory             | 512 MB                       |
| vCPUs              | 1                            |
| Graphics           | None (headless)              |
| Boot disk          | qcow2, backed by cloud image |
| Cloud-init disk    | ISO (attached as second disk) |
| NIC 1              | DHCP via bridge              |
| NIC 1 MAC          | `52:54:00:12:34:56`          |
| NIC 2              | Static IP via bridge         |
| NIC 2 MAC          | `52:54:00:12:34:57`          |
| Static IP          | `192.168.122.2/24`           |
| KVM acceleration   | Used if `/dev/kvm` is available; otherwise QEMU emulation |

### Guest VM User

| Parameter          | Default Value                |
|--------------------|------------------------------|
| Username           | `debian`                     |
| Password           | `debian`                     |

### Libvirt Network XML

The NAT network is defined with the following structure:

```xml
<network>
  <name>{network_name}</name>
  <bridge name="{bridge_name}"/>
  <forward mode="nat"/>
  <ip address="{network_address}" netmask="{netmask}">
    <dhcp>
      <range start="{dhcp_start}" end="{dhcp_end}"/>
    </dhcp>
  </ip>
</network>
```

## Cloud-Init Data

The guest VM is bootstrapped via cloud-init using three data files bundled into an ISO image.

### meta-data

```yaml
instance-id: {domain_name}
local-hostname: {domain_name}
```

### network-config

Cloud-init network configuration version 2:

```yaml
network:
  version: 2
  ethernets:
    eth0:
      match:
        macaddress: '{dhcp_mac}'
      dhcp4: true
    eth1:
      match:
        macaddress: '{static_mac}'
      addresses:
      - '{static_address}'
```

### user-data

```yaml
#cloud-config

chpasswd:
  expire: false
password: '{domain_password}'
ssh_authorized_keys:
- '{test_runner_public_key}'
```

## SSH Access to Guest VM

The test runner reaches the guest VM via `ProxyJump` through the libvirt container:

```
Host libvirt-container
    HostName {container_host}
    User {libvirt_user}
    StrictHostKeyChecking no

Host guest-vm
    HostName {guest_static_ip}
    ProxyJump libvirt-container
    User {domain_user}
    StrictHostKeyChecking no
```

- `StrictHostKeyChecking` is disabled for test automation (containers and VMs are ephemeral).
- The guest VM's static IP (NIC 2) is used for SSH access, ensuring a predictable address regardless of DHCP assignment.

## Timeouts

| Operation                | Timeout       |
|--------------------------|---------------|
| SSH port readiness       | 30 seconds    |
| Libvirt daemon readiness | 30 seconds    |
| VM login prompt          | 300 seconds   |
| SSH to guest VM          | 30 seconds    |
