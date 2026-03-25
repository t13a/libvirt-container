#!/bin/bash
set -e

for f in /docker-entrypoint.d/*.sh; do
    if [ -x "$f" ]; then
        echo "docker-entrypoint: running $f"
        "$f"
    fi
done

exec /sbin/init
