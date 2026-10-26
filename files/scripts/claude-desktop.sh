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

dnf install --installroot=$root --use-host-config -y "${dependencies[@]}"

chroot $root /bin/bash -c ""

git clone --depth 1 https://github.com/dewzor/claude-desktop-fedora.git $root/claude-desktop-fedora

# build in chroot
chroot $root /bin/bash -c "cd /claude-desktop-fedora && ./build-official.sh"

dnf install -y $root/claude-desktop-fedora/build/official/claude-desktop-*.rpm

# cleanup
echo $root
#rm -rf $root
