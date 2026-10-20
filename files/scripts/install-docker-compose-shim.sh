#!/bin/bash

tee /usr/sbin/docker-compose << 'EOF'
#!/bin/sh
exec docker compose "$@"
EOF

