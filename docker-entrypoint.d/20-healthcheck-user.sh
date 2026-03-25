#!/bin/bash
set -e

USER=healthcheck

# Create healthcheck system user if it does not exist
if ! id "$USER" &>/dev/null; then
    useradd --system --create-home --shell /bin/bash "$USER"
fi

# Add to libvirt group
usermod -aG libvirt "$USER"

HOME_DIR=$(eval echo "~$USER")

# Generate SSH keypair if not present
if [ ! -f "$HOME_DIR/.ssh/id_rsa" ]; then
    mkdir -p "$HOME_DIR/.ssh"
    chmod 700 "$HOME_DIR/.ssh"
    ssh-keygen -t rsa -N "" -f "$HOME_DIR/.ssh/id_rsa" -q
fi

# Install public key as authorized key for localhost access
cp "$HOME_DIR/.ssh/id_rsa.pub" "$HOME_DIR/.ssh/authorized_keys"
chmod 600 "$HOME_DIR/.ssh/authorized_keys"

# SSH config for localhost connection
cat > "$HOME_DIR/.ssh/config" <<EOF
Host 127.0.0.1
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel ERROR
EOF
chmod 600 "$HOME_DIR/.ssh/config"

# Configure default libvirt URI
mkdir -p "$HOME_DIR/.config/libvirt"
echo 'uri_default = "qemu+ssh://127.0.0.1/system"' > "$HOME_DIR/.config/libvirt/libvirt.conf"

# Fix ownership
chown -R "$USER:" "$HOME_DIR/.ssh" "$HOME_DIR/.config"
