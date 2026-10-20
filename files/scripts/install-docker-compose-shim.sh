#!/bin/bash

tee /usr/sbin/bin/docker-compose << 'EOF'
#!/bin/sh
exec docker compose "$@"
EOF

