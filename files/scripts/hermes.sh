#!/bin/bash

set -euo pipefail

# installing bare minimum to connect to remote gateway
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --include-desktop --hermes-home /opt/hermes --skip-setup --skip-browser --skip-computer-use

# cleanup
ln -s /opt/hermes/hermes-agent/hermes /usr/bin/hermes
