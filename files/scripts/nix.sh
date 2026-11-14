#!/bin/bash

set -euo pipefail

# install nix
dnf install -y nix
# create empty mount point
mkdir -p /nix

# SELinux rules
semanage fcontext -a -e /var/lib/nix /nix
semanage fcontext -a -t var_run_t '/var/lib/nix/var/nix/daemon-socket(/.*)?'

# Add systemd service and mount
cat >/usr/lib/systemd/system/nix-directory.service <<EOF
[Unit]
Description=Create persistent Nix directory in /var
DefaultDependencies=no
RequiresMountsFor=/var
Before=nix.mount

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/mkdir -p /var/lib/nix/store /var/lib/nix/var/nix/daemon-socket
ExecStart=/usr/sbin/restorecon -F /var/lib/nix /var/lib/nix/store /var/lib/nix/var /var/lib/nix/var/nix
ExecStart=/usr/sbin/restorecon -RF /var/lib/nix/var/nix/daemon-socket

[Install]
RequiredBy=nix.mount
EOF

cat >/usr/lib/systemd/system/nix.mount <<EOF
[Unit]
Description=Bind-mount /var/lib/nix onto /nix
Requires=nix-directory.service
After=nix-directory.service
RequiresMountsFor=/var/lib/nix

[Mount]
What=/var/lib/nix
Where=/nix
Type=none
Options=bind

[Install]
WantedBy=local-fs.target
EOF

# enable systemd units
systemd enable nix.mount
systemd enable nix-daemon.socket
