#!/bin/bash

set -euo pipefail

dnf copr enable ublue-os/packages
dnf config-manager --set-disabled "copr:copr.fedorainfracloud.org:ublue-os:packages"
dnf -y --enablerepo copr:copr.fedorainfracloud.org:ublue-os:packages install gnome-rounded-blur
