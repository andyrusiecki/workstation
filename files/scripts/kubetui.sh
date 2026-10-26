#!/bin/bash

set -euo pipefail

root=$(mktemp -d)

install_dir="/usr/bin"

# kubetui
repo="sarub0b0/kubetui"
version=$(curl -L -s -H 'Accept: application/json' https://github.com/${repo}/releases/latest | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')

download_file="kubetui-x86_64-unknown-linux-gnu"
download_url="https://github.com/${repo}/releases/download/${version}/${download_file}"

curl -L -o $root/kubetui $download_url
install -Dm 755 $root/kubetui -t "$install_dir"

# cleanup
rm -rf $root
