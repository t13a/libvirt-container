#!/bin/bash
set -e

# Generate SSH host keys if they do not already exist.
# This is idempotent — existing keys in /etc/ssh (persisted via volume) are preserved.
ssh-keygen -A
