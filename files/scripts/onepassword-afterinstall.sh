#!/bin/bash

set -euo pipefail

# chrome-sandbox requires the setuid bit to be specifically set.
# See https://github.com/electron/electron/issues/17972
chmod 4755 /opt/1Password/chrome-sandbox

# Must be over 1000
GID_ONEPASSWORD="1500"
GID_ONEPASSWORD_CLI="1600"
GID_ONEPASSWORD_MCP="1700"

ONEPASSWORD_BROWSER_SUPPORT_PATH="/opt/1Password/1Password-BrowserSupport"
ONEPASSWORD_CLI_PATH="/usr/bin/op"
ONEPASSWORD_MCP_PATH="/opt/1Password/onepassword-mcp"

# Browser Support
chgrp "${GID_ONEPASSWORD}" "${ONEPASSWORD_BROWSER_SUPPORT_PATH}"
chmod g+s "${ONEPASSWORD_BROWSER_SUPPORT_PATH}"

# CLI
chgrp "${GID_ONEPASSWORD_CLI}" "${ONEPASSWORD_CLI_PATH}"
chmod g+s "${ONEPASSWORD_CLI_PATH}"

# MCP
chgrp "${GID_ONEPASSWORD_MCP}" "${ONEPASSWORD_MCP_PATH}"
chmod g+s "${ONEPASSWORD_MCP_PATH}"

# Dynamically create the required groups via sysusers.d
# and set the GID based on the files we just chgrp'd
cat >/usr/lib/sysusers.d/onepassword.conf <<EOF
g onepassword ${GID_ONEPASSWORD}
EOF

cat >/usr/lib/sysusers.d/onepassword-cli.conf <<EOF
g onepassword-cli ${GID_ONEPASSWORD_CLI}
EOF

cat >/usr/lib/sysusers.d/onepassword-mcp.conf <<EOF
g onepassword-mcp ${GID_ONEPASSWORD_MCP}
EOF

# remove the sysusers.d entries created by onepassword RPMs.
# They don't magically set the GID like we need them to.
rm -f /usr/lib/sysusers.d/30-rpmostree-pkg-group-onepassword.conf
rm -f /usr/lib/sysusers.d/30-rpmostree-pkg-group-onepassword-cli.conf
rm -f /usr/lib/sysusers.d/30-rpmostree-pkg-group-onepassword-mcp.conf


