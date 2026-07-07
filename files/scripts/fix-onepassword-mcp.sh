#!/bin/bash

set -euo pipefail

# Addition to 1password bling installer for onepassword-mcp group

# Must be over 1000
GID_ONEPASSWORDMCP="${GID_ONEPASSWORDMCP:-1700}"

ONEPASSWORD_MCP_PATH="/opt/1Password/onepassword-mcp"

# onepassword-mcp also needs its own group and setgid, like the other helpers.
chgrp "${GID_ONEPASSWORDMCP}" "${ONEPASSWORD_MCP_PATH}"
chmod g+s "${ONEPASSWORD_MCP_PATH}"

# Dynamically create the required groups via sysusers.d
# and set the GID based on the files we just chgrp'd
cat >/usr/lib/sysusers.d/onepassword-mcp.conf <<EOF
g onepassword-mcp ${GID_ONEPASSWORDMCP}
EOF

# remove the sysusers.d entries created by onepassword RPMs.
# They don't magically set the GID like we need them to.
rm -f /usr/lib/sysusers.d/30-rpmostree-pkg-group-onepassword-mcp.conf
