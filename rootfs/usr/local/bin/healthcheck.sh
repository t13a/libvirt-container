#!/bin/bash

set -euo pipefail

su healthcheck -c 'virsh connect' || exit 1
