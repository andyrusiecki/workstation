#!/bin/bash

set -euo pipefail

# installing bare minimum to connect to remote gateway
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --include-desktop --dir /opt/hermes --skip-setup --skip-browser --skip-computer-use

# cleanup
ln -s /opt/hermes/.hermes/bin/hermes /usr/bin/hermes
