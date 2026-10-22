#!/bin/bash

set -euo pipefail

root=$(mktemp -d)

ARCH=$(uname -m)
case $ARCH in
    i386|i686) ARCH=amd64 ;;
    armv6*) ARCH=armv6 ;;
    armv7*) ARCH=armv7 ;;
    aarch64*) ARCH=arm64 ;;
esac

DIR="/usr/bin"

# prepare the download URL
GITHUB_REPO="docker/docker-credential-helpers"
GITHUB_LATEST_VERSION=$(curl -L -s -H 'Accept: application/json' https://github.com/${GITHUB_REPO}/releases/latest | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')

helpers=(
  pass
  secretservice
)

for helper in ${helpers[@]}
do
  local GITHUB_FILE="docker-credential-${helper}-${GITHUB_LATEST_VERSION}.$(uname -s | tr '[:upper:]' '[:lower:]')-${ARCH}"
  local GITHUB_URL="https://github.com/${GITHUB_REPO}/releases/download/${GITHUB_LATEST_VERSION}/${GITHUB_FILE}"

  curl -L -o $root/docker-credential-${helper} $GITHUB_URL
  install -Dm 755 $root/docker-credential-${helper} -t "$DIR"
done

# cleanup
rm -rf $root
