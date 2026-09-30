#!/usr/bin/env bash
# Build (or reset + rebuild) the project database from the submitted files.
# Usage: scripts/build.sh            (uses: mysql -u root)
#        MYSQL="mysql -u root -p" scripts/build.sh
set -euo pipefail
cd "$(dirname "$0")/.."
MYSQL=${MYSQL:-"mysql -u root"}
for f in sql/00_schema.sql sql/01_load.sql sql/02_views.sql; do
  echo ">> running $f"
  $MYSQL < "$f"
done
$MYSQL -t -e "USE p1_car_repair;
SELECT (SELECT COUNT(*) FROM business) AS businesses,
       (SELECT COUNT(*) FROM service) AS services,
       (SELECT COUNT(*) FROM service_category) AS categories,
       (SELECT COUNT(*) FROM business_service) AS offerings,
       (SELECT COUNT(*) FROM source) AS sources;"
