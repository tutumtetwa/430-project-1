# Query outputs (Q1-Q6) with checks

Generated 2026-09-30 15:09 by `scripts/run_queries.py` against `p1_car_repair`.

```text
+---------------+
| mysql_version |
+---------------+
| 8.4.5         |
+---------------+
```

## Q1

**Meaning:** Businesses whose name contains the fragment 'Auto Repair'.

```sql
-- ---------------------------------------------------------------------
-- Q1. Which businesses match a selected name fragment?
--     Parameter: @name_fragment = 'Auto Repair'
--     Output: business_id, business_name, city  (sorted by name, then id)
-- ---------------------------------------------------------------------
SET @name_fragment = 'Auto Repair';
SELECT  business_id, business_name, city
FROM    business
WHERE   business_name LIKE CONCAT('%', @name_fragment, '%')
ORDER BY business_name, business_id;
```

**Output**

```text
+-------------+------------------------------------------+---------+
| business_id | business_name                            | city    |
+-------------+------------------------------------------+---------+
|           6 | Eliot's Complete Auto Repair             | Chicago |
|           7 | Fred's Wrigleyville Garage & Auto Repair | Chicago |
|           8 | Lincoln Park Auto Repair Service         | Chicago |
|          10 | Midtown Auto Repair                      | Chicago |
|          12 | Reliable Auto Repair Center              | Chicago |
+-------------+------------------------------------------+---------+
```

**Check:** Independent method (INSTR instead of LIKE) should give the same 5 businesses; by hand from data/clean/business.csv the names containing 'Auto Repair' are Eliot's, Fred's, Lincoln Park Auto Repair Service, Midtown, Reliable.

```text
+---------------+
| expected_rows |
+---------------+
|             5 |
+---------------+
```

## Q2

**Meaning:** Chicago providers with a recorded Transmission Repair offering, each traced to its source URL and raw observation row. Evidence is for the selected location only; branch availability is unverified.

```sql
-- ---------------------------------------------------------------------
-- Q2. Which businesses in a selected city have a recorded offering for a
--     selected service?
--     Parameters: @city = 'Chicago', @service = 'Transmission Repair'
--     Output: provider, service, source URL, raw-row reference.
--     No duplicate providers: (business_id, service_id) is the PK of
--     business_service, so each provider joins to at most one offering row.
--     Limitation: evidence describes the business offering at its selected
--     location; branch availability for multi-location companies is unverified.
-- ---------------------------------------------------------------------
SET @city = 'Chicago', @service = 'Transmission Repair';
SELECT  b.business_id,
        b.business_name AS provider,
        s.service_name  AS service,
        src.url         AS source_url,
        bs.raw_row_ref
FROM    business b
JOIN    business_service bs ON bs.business_id = b.business_id
JOIN    service s           ON s.service_id   = bs.service_id
JOIN    source src          ON src.source_id  = bs.source_id
WHERE   b.city = @city
  AND   s.service_name = @service
ORDER BY b.business_name;
```

**Output**

```text
+-------------+------------------------------------------+---------------------+-----------------------------------------------+-------------+
| business_id | provider                                 | service             | source_url                                    | raw_row_ref |
+-------------+------------------------------------------+---------------------+-----------------------------------------------+-------------+
|           3 | Bucaro Brothers Auto Care                | Transmission Repair | https://www.bucarobrothersautocare.com/       | OBS:OBS011  |
|           5 | E & J Foreign Cars                       | Transmission Repair | https://www.eandj.com/auto-services           | OBS:OBS029  |
|           6 | Eliot's Complete Auto Repair             | Transmission Repair | https://www.eliotscompleteautorepair.com/     | OBS:OBS024  |
|           7 | Fred's Wrigleyville Garage & Auto Repair | Transmission Repair | http://fredswrigleyvillegarage.com            | OBS:OBS036  |
|           8 | Lincoln Park Auto Repair Service         | Transmission Repair | https://www.lincolnparkautorepairservice.com/ | OBS:OBS041  |
|          15 | Sun Auto Service                         | Transmission Repair | https://www.sunautoserviceinc.com/            | OBS:OBS067  |
+-------------+------------------------------------------+---------------------+-----------------------------------------------+-------------+
```

**Check:** Row count must equal the number of DISTINCT providers (no duplicates), and a spot check traces Bucaro Brothers to raw row OBS011 'Transmission Services'.

```text
+---------------+--------------------+
| offering_rows | distinct_providers |
+---------------+--------------------+
|             6 |                  6 |
+---------------+--------------------+
+---------------------------+-------------+-----------------------+
| business_name             | raw_row_ref | observed_wording      |
+---------------------------+-------------+-----------------------+
| Bucaro Brothers Auto Care | OBS:OBS011  | Transmission Services |
+---------------------------+-------------+-----------------------+
```

## Q3

**Meaning:** Services offered by at least 7 distinct businesses in the sample (threshold @min_providers = 7).

```sql
-- ---------------------------------------------------------------------
-- Q3. Which services have at least a chosen number of providers?
--     Parameter: @min_providers = 7
--     Output: service_name, provider_count (distinct businesses)
-- ---------------------------------------------------------------------
SET @min_providers = 7;
SELECT  s.service_name,
        COUNT(DISTINCT bs.business_id) AS provider_count
FROM    service s
JOIN    business_service bs ON bs.service_id = s.service_id
GROUP BY s.service_id, s.service_name
HAVING  COUNT(DISTINCT bs.business_id) >= @min_providers
ORDER BY provider_count DESC, s.service_name;
```

**Output**

```text
+----------------------+----------------+
| service_name         | provider_count |
+----------------------+----------------+
| Vehicle Diagnostics  |             14 |
| Brake Repair         |             11 |
| Tire Service         |              9 |
| Oil Change           |              8 |
| A/C & Heating Repair |              7 |
+----------------------+----------------+
```

**Check:** Manual count per service using plain COUNT(*) over the associative table (valid because the composite PK forbids duplicate pairs). Services with >= 7 must match Q3.

```text
+------------+--------------+
| service_id | manual_count |
+------------+--------------+
|          5 |           14 |
|          4 |           11 |
|          2 |            9 |
|          1 |            8 |
|          7 |            7 |
|          6 |            6 |
|          3 |            5 |
+------------+--------------+
```

## Q4

**Meaning:** Businesses with no Wheel Alignment offering *recorded* in our sample. Absence means 'not recorded', not proof the shop lacks the service.

```sql
-- ---------------------------------------------------------------------
-- Q4. Which businesses have NO offering recorded for a selected service?
--     Parameter: @service = 'Wheel Alignment'
--     Output: business_id, business_name
--     Interpretation: "not recorded in our sample", NOT proof the shop
--     does not provide the service.
-- ---------------------------------------------------------------------
SET @service = 'Wheel Alignment';
SELECT  b.business_id, b.business_name
FROM    business b
WHERE   NOT EXISTS (
            SELECT 1
            FROM   business_service bs
            JOIN   service s ON s.service_id = bs.service_id
            WHERE  bs.business_id = b.business_id
              AND  s.service_name = @service)
ORDER BY b.business_name;
```

**Output**

```text
+-------------+----------------------------------+
| business_id | business_name                    |
+-------------+----------------------------------+
|           2 | Autohaus                         |
|           4 | Cassidy Tire & Service           |
|           5 | E & J Foreign Cars               |
|           8 | Lincoln Park Auto Repair Service |
|           9 | Mechanista                       |
|          10 | Midtown Auto Repair              |
|          11 | North Center Auto Service        |
|          12 | Reliable Auto Repair Center      |
|          13 | Rockwell Auto Clinic             |
|          14 | Speedline Auto & Tire            |
|          15 | Sun Auto Service                 |
+-------------+----------------------------------+
```

**Check:** 16 businesses minus the 5 with a recorded Wheel Alignment offering = 11 expected rows.

```text
+------------------+----------------+---------------+
| total_businesses | with_alignment | expected_rows |
+------------------+----------------+---------------+
|               16 |              5 |            11 |
+------------------+----------------+---------------+
```

## Q5

**Meaning:** All 7 service types for Mechanista (business 9); NULL = no offering recorded for that service.

```sql
-- ---------------------------------------------------------------------
-- Q5. For a selected business, list every service type and the matched
--     business_id from the offering, or NULL when none is recorded.
--     Parameter: @business_id = 9  (Mechanista)
--     The business filter sits in the LEFT JOIN's ON clause; putting it in
--     WHERE would discard the unmatched (NULL) service rows.
-- ---------------------------------------------------------------------
SET @business_id = 9;
SELECT  s.service_id,
        s.service_name,
        bs.business_id AS matched_business_id
FROM    service s
LEFT JOIN business_service bs
       ON bs.service_id  = s.service_id
      AND bs.business_id = @business_id
ORDER BY s.service_id;
```

**Output**

```text
+------------+----------------------+---------------------+
| service_id | service_name         | matched_business_id |
+------------+----------------------+---------------------+
|          1 | Oil Change           |                   9 |
|          2 | Tire Service         |                   9 |
|          3 | Wheel Alignment      |                NULL |
|          4 | Brake Repair         |                   9 |
|          5 | Vehicle Diagnostics  |                   9 |
|          6 | Transmission Repair  |                NULL |
|          7 | A/C & Heating Repair |                NULL |
+------------+----------------------+---------------------+
```

**Check:** Q5 must return one row per service (7). Mechanista has 4 recorded offerings, so 4 rows show 9 and 3 rows show NULL.

```text
+---------------+-------------------+
| expected_rows | expected_non_null |
+---------------+-------------------+
|             7 |                 4 |
+---------------+-------------------+
```

## Q6

**Meaning:** Businesses in the directory view with no working website recorded.

```sql
-- ---------------------------------------------------------------------
-- Q6. Which businesses in the directory view have no recorded website?
--     Uses v_business_directory from 02_views.sql.
--     Output: business_id, business_name, city
-- ---------------------------------------------------------------------
SELECT  business_id, business_name, city
FROM    v_business_directory
WHERE   website IS NULL
ORDER BY business_name, business_id;
```

**Output**

```text
+-------------+---------------+---------+
| business_id | business_name | city    |
+-------------+---------------+---------+
|           2 | Autohaus      | Chicago |
+-------------+---------------+---------+
```

**Check:** Base-table count of NULL websites must match the view. Autohaus is NULL because its listed domain autohauschicago.com 301-redirects to an unrelated company (data/raw/snapshots/autohauschicago_redirect_headers.txt).

```text
+-----------------------------+
| null_websites_in_base_table |
+-----------------------------+
|                           1 |
+-----------------------------+
```
