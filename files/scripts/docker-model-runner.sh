#!/bin/bash

set -euo pipefail

dependencies=(
  cmake
  gcc-c++
)

root=$(mktemp -d)

dnf install -y "${dependencies[@]}"

git clone --depth 1 https://github.com/docker/model-runner.git $root/model-runner

# build in chroot
(
  cd $root/model-runner
  make build-cli
  make install-cli
)

# cleanup
rm -rf $root
