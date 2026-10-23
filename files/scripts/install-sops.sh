#!/bin/bash

set -euo pipefail

root=$(mktemp -d)

arch=$(uname -m)
case $arch in
    x86*) arch=amd64 ;;
    i386|i686) arch=amd64 ;;
    aarch64*) arch=arm64 ;;
esac

install_dir="/usr/bin"

# sops
repo="getsops/sops"
version=$(curl -L -s -H 'Accept: application/json' https://github.com/${repo}/releases/latest | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')

download_file="sops-${version}.$(uname -s | tr '[:upper:]' '[:lower:]').${arch}"
download_url="https://github.com/${repo}/releases/download/${version}/${download_file}"

curl -L -o $root/sops $download_url
install -Dm 755 $root/sops -t "$install_dir"

# ssh-to-age
repo="Mic92/ssh-to-age"
version=$(curl -L -s -H 'Accept: application/json' https://github.com/${repo}/releases/latest | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')

download_file="ssh-to-age.$(uname -s | tr '[:upper:]' '[:lower:]')-${arch}"
download_url="https://github.com/${repo}/releases/download/${version}/${download_file}"

curl -L -o $root/ssh-to-age $download_url
install -Dm 755 $root/ssh-to-age -t "$install_dir"

# cleanup
rm -rf $root
