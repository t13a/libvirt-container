#!/bin/bash

set -euo pipefail

for SCRIPT in $(ls /usr/local/lib/entrypoint.d/*.sh)
do
    echo "Executing ${SCRIPT}" >&2
    "${SCRIPT}"
done

if [ ${#@} -eq 0 ]
then
    exec supervisord -c /etc/supervisord.conf
else
    exec "${@}"
fi
