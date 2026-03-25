#!/bin/bash
set -e

# Disable polkit authorization for libvirt.
# Polkit requires logind which is unavailable inside containers.
CONF="/etc/libvirt/libvirtd.conf"

if ! grep -q '^access_drivers = \[ "none" \]' "$CONF" 2>/dev/null; then
    cat > "$CONF" <<'EOF'
# Bypass polkit authorization (polkit requires logind which is unavailable in containers)
access_drivers = [ "none" ]
EOF
fi
