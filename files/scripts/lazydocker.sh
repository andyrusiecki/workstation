#!/bin/bash

set -euo pipefail

root=$(mktemp -d)

arch=$(uname -m)
case $arch in
    x86_64) arch=x86_64 ;;
    x86*) arch=x86 ;;
    i386|i686) arch=x86 ;;
    armv6*) arch=armv6 ;;
    armv7*) arch=armv7 ;;
    aarch64*) arch=arm64 ;;
esac

install_dir="/usr/bin"

# prepare the download URL
repo="jesseduffield/lazydocker"
version=$(curl -L -s -H 'Accept: application/json' https://github.com/${repo}/releases/latest | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')

download_file="lazydocker_${version//v/}_$(uname -s)_${arch}.tar.gz"
download_url="https://github.com/${repo}/releases/download/${version}/${download_file}"

curl -L -o $root/lazydocker.tar.gz $download_url
tar xzvf $root/lazydocker.tar.gz
install -Dm 755 $root/lazydocker -t "$install_dir"

# cleanup
rm -rf $root
