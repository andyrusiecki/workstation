#!/bin/bash

# Building from https://github.com/tirtha4/Granola-for-Linux

set -euo pipefail

dependencies=(
  gcc-c++
  nodejs
  npm
  python3
  curl
  make
)

root=$(mktemp -d)

dnf install -y "${dependencies[@]}"

# download mac dmg
curl -L https://api.granola.ai/v1/download-latest?full_dmg=true --output $root/Granola.dmg

# clone repo
git clone --depth 1 https://github.com/tirtha4/Granola-for-Linux.git $root/Granola-for-Linux

# build in chroot
cd $root/Granola-for-Linux

export INSTALL_DIR="/opt/granola"
export DESKTOP_FILE="/usr/share/applications/granola.desktop"

./granola-linux.sh ../Granola.dmg

# cleanup
rm -rf $root
