#!/bin/bash

set -euo pipefail

# install nix
dnf install -y nix
# create empty mount point
mkdir -p /nix

# SELinux rules
semanage fcontext -a -e /var/lib/nix /nix
semanage fcontext -a -t var_run_t '/var/lib/nix/var/nix/daemon-socket(/.*)?'
