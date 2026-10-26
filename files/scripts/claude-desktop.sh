#!/bin/bash

set -euo pipefail

dependencies=(
  rpm-build
  binutils
  file
  xz
  curl
  gnupg2
)

root=$(mktemp -d)

dnf install -y "${dependencies[@]}"

git clone --depth 1 https://github.com/dewzor/claude-desktop-fedora.git $root/claude-desktop-fedora

# build
(
    cd $root/claude-desktop-fedora
    ./build-official.sh
)

dnf install -y $root/claude-desktop-fedora/build/official/claude-desktop-*.rpm

# cleanup
rm -rf $root
