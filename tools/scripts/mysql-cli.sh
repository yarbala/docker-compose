#!/bin/bash

cd "$(dirname "$0")/.." || exit

set -a
source .env
set +a
docker compose exec mysql-server mysql -uroot -p"$MYSQL_ROOT_PASSWORD"