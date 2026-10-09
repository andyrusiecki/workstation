#!/bin/bash

set -euo pipefail

dnf -y copr enable ublue-os/packages
dnf config-manager setopt copr:copr.fedorainfracloud.org:ublue-os:packages.enabled=0
dnf -y --enablerepo copr:copr.fedorainfracloud.org:ublue-os:packages install gnome-rounded-blur
