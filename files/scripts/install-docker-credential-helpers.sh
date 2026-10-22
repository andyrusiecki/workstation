#!/bin/bash

set -euo pipefail

root=$(mktemp -d)

arch=$(uname -m)
case $arch in
    i386|i686) arch=amd64 ;;
    armv6*) arch=armv6 ;;
    armv7*) arch=armv7 ;;
    aarch64*) arch=arm64 ;;
esac

install_dir="/usr/bin"

# prepare the download URL
repo="docker/docker-credential-helpers"
version=$(curl -L -s -H 'Accept: application/json' https://github.com/${repo}/releases/latest | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')

helpers=(
  pass
  secretservice
)

for helper in ${helpers[@]}
do
  download_file="docker-credential-${helper}-${version}.$(uname -s | tr '[:upper:]' '[:lower:]')-${arch}"
  download_url="https://github.com/${repo}/releases/download/${version}/${download_file}"

  curl -L -o $root/docker-credential-${helper} $download_url
  install -Dm 755 $root/docker-credential-${helper} -t "$install_dir"
done

# cleanup
rm -rf $root
