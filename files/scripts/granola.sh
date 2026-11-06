#!/bin/bash

# Building from https://github.com/tirtha4/Granola-for-Linux

set -euo pipefail

dependencies=(
  7zip-standalone-all
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
# curl -L https://api.granola.ai/v1/download-latest?full_dmg=true --output $root/Granola.dmg

# Pinned: Granola 7.749.1+ no longer ships the C++ source (deps/, src/) of its
# better-sqlite3-multiple-ciphers fork, which granola-linux.sh must rebuild for
# Linux. 7.726.2 is the last release known to include it.
granola_version=7.726.2
granola_sha256=ba388e640688f07d9273690842ac13183dfbe71d9ce7d67c9208cdaf96654c8c
curl -fL "https://dr2v7l5emb758.cloudfront.net/$granola_version/Granola-$granola_version-mac-universal.dmg" --output $root/Granola.dmg
echo "$granola_sha256  $root/Granola.dmg" | sha256sum -c -

# clone repo
git clone --depth 1 https://github.com/tirtha4/Granola-for-Linux.git $root/Granola-for-Linux

# build in chroot
cd $root/Granola-for-Linux

export INSTALL_DIR="/opt/granola"
export DESKTOP_FILE="/usr/share/applications/granola.desktop"

./granola-linux.sh ../Granola.dmg

# custom changes
sed -i 's#Icon=.*#Icon=/opt/granola/resources/icons/mac-icon.png#' /usr/share/applications/granola.desktop

# cleanup
rm -rf $root
