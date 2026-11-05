#!/bin/bash

set -euo pipefail

# prepare the download URL
repo="OpenWhispr/openwhispr"
version=$(curl -L -s -H 'Accept: application/json' https://github.com/${repo}/releases/latest | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')

rpm_file="OpenWhispr-${version}-linux-x86_64.rpm"
rpm_url="https://github.com/${repo}/releases/download/${version}/${download_file}"

dnf -y install "$rpm_url"
