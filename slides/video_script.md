# 20-minute video run sheet

Before recording: build the database once (`scripts/build.sh`), and open
`slides.pdf`, `report.pdf` (page 3), a terminal logged into `mysql`, and
`data/raw/manual_observations.csv`.

## 0:00–3:00  Question, scope, source trace (Saron)
1. Slide 1: state the user question, the scope, and the counts (16 / 7 / 2 / 60).
2. Trace one offering from the database back to the raw observation:
   ```sql
   USE p1_car_repair;
   SELECT b.business_name, b.raw_row_ref AS license_row, s.service_name,
          bs.observed_wording, bs.raw_row_ref, src.url, src.raw_file
   FROM business_service bs
   JOIN business b ON b.business_id = bs.business_id
   JOIN service s  ON s.service_id  = bs.service_id
   JOIN source src ON src.source_id = bs.source_id
   WHERE bs.business_id = 3 AND bs.service_id = 6;
   ```
   Then open `manual_observations.csv` at row **OBS011** and `snapshots/SRC03.html`.
   Point out the difference: "Transmission Services" is what the page said
   (observation), while *Transmission Repair* is our standard service
   (classification).
3. Cleaning decision: the E & J site says "Diagnostic Resting" (a typo). We keep
   it in the raw log and map it to Vehicle Diagnostics (OBS028).

## 3:00–7:00  ER diagram, keys, normalization (Eyael)
Report page 3 and slide 2: explain the 1:N (category → service), the M:N through
`business_service`, the composite PK, NOT NULL FKs to `source`, and the CASCADE
vs RESTRICT choices. Then walk through the normalization: FDs → 3NF tables, and
how Fred's website repeated 7 times shows the anomaly.

## 7:00–11:00  Build and validation (Tutu)
```bash
mysql -u root -p < sql/00_schema.sql
mysql -u root -p < sql/01_load.sql
mysql -u root -p < sql/02_views.sql
mysql -u root -p -t < tests/t1_counts.sql            # counts + source-link check
mysql -u root -p -t --force < tests/t2_fk_reject.sql  # ERROR 1452
mysql -u root -p -t --force < tests/t3_duplicate_reject.sql  # ERROR 1062
```

## 11:00–15:00  Q2 + one of Q3–Q6 (all three: Saron runs Q2, Eyael runs Q5, Tutu explains the finding and limitation)
Run Q2 (Transmission Repair) and **Q5** (Mechanista, business 9). For Q5, explain
why the filter sits in `ON`: move it to `WHERE` live and show that the 3 NULL
rows disappear.
- **Finding:** diagnostics are the most widely listed service (14 of 16); alignment is recorded at only 5.
- **Limitation:** absence means "not recorded", not "not offered".

## 15:00–20:00  Individual segments (about 1.5 minutes each)
Each member (1) explains one key or constraint and why it's needed, and
(2) changes one filter and explains the before/after results. Suggested split, no overlap:

| Member | Constraint to explain | Query change (before → after) |
|---|---|---|
| Saron | Composite PK `(business_id, service_id)`: shows T3 | Q3 `@min_providers = 7` → `10` (5 rows → 2: Diagnostics 14, Brakes 11) |
| Eyael | FK `business_service.service_id` RESTRICT: shows T2b | Q4 `@service = 'Wheel Alignment'` → `'Vehicle Diagnostics'` (11 rows → 2: Midtown, Speedline) |
| Tutu | FK `business.source_id` NOT NULL (BR3 provenance) | Q1 `@name_fragment = 'Auto Repair'` → `'Tire'` (5 rows → 4: Ashland, Cassidy, Speedline, Tuffy) |

Label each speaker by name on screen, and fill in the timestamp table in README.md.
