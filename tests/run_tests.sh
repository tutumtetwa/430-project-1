#!/usr/bin/env bash
# Runs T1-T4 and writes tests/test_log.md.
# Intentional-error tests (T2, T3) run separately from the successful build;
# T4 runs in the isolated database p1_fixture, which is dropped afterwards.
set -uo pipefail
cd "$(dirname "$0")/.."
MYSQL=${MYSQL:-"mysql -u root"}
LOG=tests/test_log.md

section() { printf '\n## %s\n\n' "$1" >> "$LOG"; }
block()   { printf '```text\n' >> "$LOG"; cat >> "$LOG"; printf '```\n' >> "$LOG"; }

{
  echo "# Test log (T1-T4)"
  echo
  echo "- Run at: $(date '+%Y-%m-%d %H:%M:%S %Z')"
  echo "- Server: $($MYSQL -N -e 'SELECT VERSION()')"
  echo "- Command: \`tests/run_tests.sh\`"
} > "$LOG"

section "Clean build (00 -> 01 -> 02), run twice to show no duplicate accumulation"
{ scripts/build.sh 2>&1; echo "--- second build ---"; scripts/build.sh 2>&1; } | block

section "T1 - counts and source-link checks on the real snapshot"
echo "Expected: every row PASS." >> "$LOG"; echo >> "$LOG"
$MYSQL -t < tests/t1_counts.sql 2>&1 | block

section "T2 - FK rejects offering with nonexistent business / service"
echo "Expected: two ERROR 1452 (foreign key constraint fails); offering count stays 60." >> "$LOG"; echo >> "$LOG"
$MYSQL -t --force < tests/t2_fk_reject.sql 2>&1 | block

section "T3 - composite PK rejects duplicate business-service pair"
echo "Expected: ERROR 1062 Duplicate entry '3-1'; offering count stays 60." >> "$LOG"; echo >> "$LOG"
$MYSQL -t --force < tests/t3_duplicate_reject.sql 2>&1 | block

section "T4 - isolated fixture (p1_fixture): absent offering, outer join, missing website, Q3 count"
echo "Expected: every check row PASS. The fixture database is dropped afterwards." >> "$LOG"; echo >> "$LOG"
{
  sed 's/p1_car_repair/p1_fixture/g' sql/00_schema.sql | $MYSQL
  sed 's/p1_car_repair/p1_fixture/g' sql/02_views.sql  | $MYSQL
  $MYSQL p1_fixture < tests/t4_fixture_data.sql
  $MYSQL -t p1_fixture < tests/t4_fixture_checks.sql
  $MYSQL -e "DROP DATABASE p1_fixture;" && echo "p1_fixture dropped."
} 2>&1 | block

section "Post-test: real snapshot is unchanged and uncontaminated"
$MYSQL -t -e "USE p1_car_repair;
SELECT (SELECT COUNT(*) FROM business) AS businesses,
       (SELECT COUNT(*) FROM business_service) AS offerings,
       (SELECT COUNT(*) FROM business WHERE business_name LIKE 'FIXTURE%') AS fixture_rows,
       (SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name='p1_fixture') AS fixture_db_exists;" 2>&1 | block

echo "Wrote $LOG"
