#!/bin/bash

set -euo pipefail

# ensure dependencies are installed
dependencies=(
  cmake
  vulkan-headers
  vulkan-utility-libraries-devel
)

# check if dependencies are already installed, if not add them to the list of packages to cleanup after installation
to_clean=()
for dep in "${dependencies[@]}"; do
  if ! rpm -q $dep &> /dev/null; then
    echo "Installing dependency: $dep"
    to_clean+=("$dep")
  fi
done

dnf install -y "${dependencies[@]}"

# create working directory
workdir=$(mktemp -d)
cd $workdir

git clone --depth 1 https://github.com/Korthos-Software/low_latency_layer.git
cd low_latency_layer

cmake -B build ./
cd ./build
make install

# cleanup
dnf remove -y "${to_clean[@]}"

rm -rf $workdir
