#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

cd /

# create db
./create-db.sh

# create data dir
mkdir -p /app/wp-content

chown www-data:www-data /app -R
chmod -R 777 /app/wp-content

# wait forever
tail /dev/null -f
