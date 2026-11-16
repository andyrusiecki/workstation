#!/bin/bash

set -euo pipefail

root=$(mktemp -d)

cargo install --git https://github.com/googleworkspace/cli --locked --root $root

install -Dm 755 $root/bin/gws -t /usr/bin

# cleanup
rm -rf $root
