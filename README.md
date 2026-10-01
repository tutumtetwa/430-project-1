# P1: Chicago North Side Car Repair Directory (CS 284 / CS 430, Fall 2026)

**Team: Project 1 Team:** Saron, Eyael, Tutu

**Intended user:** a driver on Chicago's North Side who wants to know which nearby
independent repair shops offer a specific service (brakes, alignment, transmission,
and so on), and where that claim came from.

**Scope:** shops with an active City of Chicago *Motor Vehicle Services License* in
Lake View, Lincoln Park, Lincoln Square, and North Center. Each shop has one
selected location. Collected 2026-09-30.

**Final dataset:** 16 businesses · 7 services in 2 categories · 60 distinct
business–service offerings · 21 sources from 21 publishers (17 cited directly by
business or offering rows) · 4 businesses corroborated.

## Team

All three members wrote code and did research together. The work was divided
as follows, and every member reviewed and tested the whole project.

| Member | Research | Code | Write-up |
|---|---|---|---|
| Saron | City of Chicago license extract; shops 1–5 (Ashland, Autohaus, Bucaro, Cassidy, E & J) | `sql/00_schema.sql`, `sql/02_views.sql`; tests T2 and T3 (constraint rejections) | `data/cleaning_note.md` |
| Eyael | Shops 6–10 (Eliot's, Fred's, Lincoln Park Auto, Mechanista, Midtown); corroboration lookups | `sql/03_queries.sql` (Q1–Q6), `scripts/run_queries.py`; test T4 (fixture) | `report.pdf` sections 1–3 + ER diagram (scope, model, normalization) |
| Tutu | Shops 11–16 (North Center, Reliable, Rockwell, Speedline, Sun, Tuffy) | `scripts/build_load_sql.py` / `sql/01_load.sql`, `scripts/build.sh`; test T1, `tests/run_tests.sh` | `report.pdf` section 4 (findings, limitation, follow-up); `README.md`; `data/source_register.csv` |

The raw observation log (`data/raw/manual_observations.csv`) was entered under
one account (`tutumtetwa`), so its `collector` column shows that name on every row.

## Requirements

* **MySQL 8.4.5** (MySQL Community Server, macOS x86_64). This is the version
  every output in `outputs/` and `tests/` was produced on. Any MySQL 8.0+ should
  work; `00_schema.sql` uses the `utf8mb4_0900_ai_ci` collation (8.0+).
* The `mysql` command-line client. Python 3 and Bash are needed **only** for the
  helper scripts (regenerating `01_load.sql`, running the tests, writing outputs).
  They are not needed to build the database.
* No network access is needed. All inputs are in this ZIP.

## Build (run order)

From the project root:

```bash
mysql -u root -p < sql/00_schema.sql    # drops and recreates ONLY database p1_car_repair
mysql -u root -p < sql/01_load.sql      # loads the real snapshot (16 / 7 / 2 / 60 / 21)
mysql -u root -p < sql/02_views.sql     # creates v_business_directory
mysql -u root -p < sql/03_queries.sql   # runs Q1-Q6
```

The same build as one command: `MYSQL="mysql -u root -p" scripts/build.sh` (prints the counts).

**Reset / second clean run:** run `00_schema.sql` again. It starts with
`DROP DATABASE IF EXISTS p1_car_repair` and touches nothing else. `01_load.sql`
also deletes its own rows before inserting, so re-running it alone never
duplicates data. `tests/test_log.md` shows two consecutive builds with identical
counts.

Foreign-key enforcement: InnoDB tables, `SET FOREIGN_KEY_CHECKS = 1` in the
scripts, verified in T1.

## Tests and outputs

```bash
MYSQL="mysql -u root -p" tests/run_tests.sh        # T1-T4 -> tests/test_log.md
MYSQL="mysql -u root -p" python3 scripts/run_queries.py   # Q1-Q6 + checks -> outputs/query_outputs.md
```

(With `-p` you will be prompted for the password several times. Alternatively,
put credentials in `~/.my.cnf`. Credentials are never stored in this ZIP.)

| Test | File | Shows |
|---|---|---|
| T1 | `tests/t1_counts.sql` | ≥15 businesses, ≥4 services, ≥2 categories, ≥20 offerings, ≥2 publishers; every business/offering has a valid source + raw-row ref |
| T2 | `tests/t2_fk_reject.sql` | FK rejects offering for nonexistent business (999) and service (99): ERROR 1452 |
| T3 | `tests/t3_duplicate_reject.sql` | Composite PK rejects duplicate pair (3, 1): ERROR 1062 |
| T4 | `tests/t4_fixture_data.sql`, `tests/t4_fixture_checks.sql` | Isolated DB `p1_fixture` (dropped afterwards): Q4 absence, Q5 outer join, Q6 missing website, Q3 vs manual count |

## Tables and keys

| Table | Purpose | Primary key | Foreign keys |
|---|---|---|---|
| `source` | Source register: publisher, title, URL, access date, saved-file path | `source_id` | none |
| `service_category` | Groups services (Routine Maintenance; Repair & Diagnostics) | `category_id` | none |
| `service` | 7 standardized service types | `service_id` | `category_id` → `service_category` (RESTRICT) |
| `business` | One shop at one selected address; website optional (NULL) | `business_id` (+ UNIQUE `business_name, street_address`) | `source_id` → `source` (RESTRICT) |
| `business_service` | Associative M:N table: one row per offering, with the observed wording, source, and raw-row ref | (`business_id`, `service_id`) | `business_id` → `business` (CASCADE); `service_id` → `service` (RESTRICT); `source_id` → `source` (RESTRICT) |

Column types, NOT NULLs, and deletion behavior are documented in the comments of `sql/00_schema.sql`.

**Raw-row references:** `business.raw_row_ref = 'LIC:<id>'` points to the `id` column of
`data/raw/chicago_business_licenses_2026-09-30.csv`. `business_service.raw_row_ref = 'OBS:<id>'`
points to `raw_row_id` in `data/raw/manual_observations.csv`. The source's saved copy is at `source.raw_file`.

## File map

```
README.md
report.pdf                         two-page report + ER diagram page
sql/00_schema.sql 01_load.sql 02_views.sql 03_queries.sql
tests/run_tests.sh t1..t4 *.sql test_log.md
outputs/query_outputs.md           Q1-Q6 outputs + checks
data/raw/chicago_business_licenses_2026-09-30.csv   unchanged city download
data/raw/manual_observations.csv   manual observation log (OBS001-OBS083)
data/raw/snapshots/                saved HTML of every cited page (embedded third-party Mapbox
                                   keys replaced with pk.REDACTED_MAPBOX_TOKEN; content otherwise unchanged)
data/source_register.csv           source register (loads the source table)
data/clean/*.csv                   cleaned loading files
data/cleaning_note.md              rules, before/after, counts, exclusions, corroboration
scripts/build_load_sql.py          regenerates sql/01_load.sql from data/clean + register
scripts/build.sh, scripts/run_queries.py
report/                            HTML source for report.pdf
```

## AI-use statement

**Tools:** Claude (Anthropic), used through Claude Code. No paid subscriptions
beyond the course-allowed tools; no prompt transcripts are included.

**Tasks:** finding candidate shops by web search; drafting the SQL schema, view,
queries, and test scripts; generating the load script; and drafting the README
and report text.

**Verification:** every service offering was checked against the saved HTML
snapshot of the cited page, and the exact wording is stored in
`observed_wording`. Business names and addresses come from the City of Chicago
license file, not from AI output. Four businesses were cross-checked against a
second independent publisher. All queries and tests were run on MySQL 8.4.5, and
their outputs are included in `outputs/` and `tests/`. All three members reviewed
the schema and SQL.

**Individual statements:**

Tutu: I used Claude to search for candidate shops and to draft the SQL, the load script, the tests, and the README. I verified shops 11-16 against the saved pages in data/raw/snapshots/ and ran the build, Q1-Q6, and T1-T4 myself.
