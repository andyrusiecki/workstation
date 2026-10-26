#!/bin/bash

set -euo pipefail

dependencies=(
  cmake
  gcc-c++
  vulkan-headers
  vulkan-loader-devel
  vulkan-utility-libraries-devel
)

root=$(mktemp -d)

dnf install --installroot=$root --use-host-config -y "${dependencies[@]}"

chroot $root /bin/bash -c ""

git clone --depth 1 https://github.com/Korthos-Software/low_latency_layer.git $root/low_latency_layer

# build in chroot
chroot $root /bin/bash -c "cd /low_latency_layer && cmake -B build ./ && cd build && make install"

# copy artifacts out of chroot
cp $root/usr/local/lib64/libVkLayer_KORTHOS_LowLatency.so /usr/lib64/
cp $root/usr/local/share/vulkan/implicit_layer.d/low_latency_layer.json /usr/share/vulkan/implicit_layer.d/

sed -i 's/\/usr\/local/\/usr/g' /usr/share/vulkan/implicit_layer.d/low_latency_layer.json

install -Dm644 $root/low_latency_layer/LICENSE -t /usr/share/licenses/VK_LAYER_KORTHOS_low_latency

# cleanup
rm -rf $root
