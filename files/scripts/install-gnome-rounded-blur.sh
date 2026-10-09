#!/bin/bash

set -euo pipefail

dnf -y copr enable ublue-os/packages
dnf config-manager disable copr:copr.fedorainfracloud.org:ublue-os:packages
dnf -y --enablerepo copr:copr.fedorainfracloud.org:ublue-os:packages install gnome-rounded-blur
