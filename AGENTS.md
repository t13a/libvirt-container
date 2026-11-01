# libvirt-container

libvirt-container runs libvirt with QEMU/KVM in a privileged Docker container, as a disposable host of VMs for development. [README.md](README.md) describes how to use it.

Write all documentation, code comments, commit messages, and GitHub issues and pull requests in English.

## Design

- **Debian sets the services up.** The image installs the packages of Debian 13 (`debian:trixie`, the full image, since the container is for development) and lets their installation configure and enable the services. Do not write systemd units by hand.
- **systemd is PID 1.** `docker-entrypoint.sh` runs the scripts in `docker-entrypoint.d/` in the order of their names, then execs `/sbin/init`. A setting under a volume, such as `/etc/libvirt`, goes into a script there rather than into the Dockerfile, because a volume that already exists keeps its old files.
- **libvirt starts on demand.** Debian 13 runs the monolithic `libvirtd`, which `libvirtd.socket` starts at the first connection. The modular daemons, such as `virtqemud`, are in other packages.

## The entry point

| Script | Does |
|---|---|
| `05-libvirt-polkit.sh` | Sets `access_drivers = [ "none" ]` in `/etc/libvirt/libvirtd.conf`: polkit needs logind, which does not run in the container. |
| `10-ssh-hostkeys.sh` | Generates the SSH host keys that are missing. `/etc/ssh` is a volume, so the host keys stay. |
| `20-healthcheck-user.sh` | Creates the user `healthcheck`, in the group `libvirt`, with an SSH key and the URI `qemu+ssh://127.0.0.1/system`. The health check, `su healthcheck -c 'virsh connect'`, so connects as a user without root does. |
| `30-libvirt-user.sh` | Creates the user `libvirt-user`, in the group `libvirt`. |
| `40-libvirt-user-password.sh` | Sets its password from `LIBVIRT_USER_PASSWORD`, if that is set. |
| `50-libvirt-user-sudo.sh` | Gives it sudo without a password. |
| `60-libvirt-user-ssh.sh` | Writes `SSH_AUTHORIZED_KEYS`, if that is set, to its `authorized_keys`. Its home is not a volume, so the keys come from the environment at each start. |

## Development

```console
$ make build       # build the image
$ make test        # run the end-to-end test
$ make test-clean  # delete the containers, images and volumes of the test
```

### The test

`molecule/default/docker-compose.yml` starts two containers: the libvirt container under test, and a test runner with Ansible and Molecule, which reaches it over SSH. Molecule uses its default driver, unmanaged, since Compose creates the containers.

`molecule/default/verify.yml` runs these steps in order, and its `vars` hold their parameters:

1. **SSH:** waits for the port, logs in with the password, installs a public key, and logs in with the key.
2. **libvirt:** `virsh connect` succeeds.
3. **Images:** downloads the daily Debian 13 cloud image, creates an overlay on it, and builds the cloud-init ISO.
4. **Network:** defines, autostarts and starts the NAT network `default`.
5. **VM:** defines the VM from `virt-install --print-xml`, autostarts and starts it, and logs in to it with SSH through the container. The guest has two NICs, one by DHCP, and one at `192.168.122.2`, which the test reaches.

What the test has taught:

- **A headless Debian 13:** under the BIOS, GRUB of the cloud image resets a VM that has no video device over and over, unless its boot disk is IDE. UEFI (`--boot=uefi`) avoids that, on Q35 with virtio disks.
- **The cloud-init ISO:** `genisoimage -volid cidata -joliet -rock` keeps the names of its files.
- **The guest:** cloud-init takes about 50 seconds, so the SSH to the guest retries.

### CI

The workflow runs the test for a tag `v*`, and when it is run by hand from the Actions tab. A tag, such as `v0.1.0`, then publishes the image to `ghcr.io/t13a/libvirt-container`, under its version and as `latest`.
