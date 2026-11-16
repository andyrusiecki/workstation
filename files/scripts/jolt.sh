#!/bin/bash

set -euo pipefail

root=$(mktemp -d)

cargo install jolt-tui --locked --root $root

install -Dm 755 $root/bin/jolt -t /usr/bin

# cleanup
rm -rf $root
