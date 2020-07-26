#!/usr/bin/env bash

set -euo pipefail

mkdir -p /run/dbus

if [ ! -f /var/lib/dbus/machine-id ]
then
    dbus-uuidgen > /var/lib/dbus/machine-id
fi
