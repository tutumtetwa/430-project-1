# Test log (T1-T4)

- Run at: 2026-09-30 15:09:44 CDT
- Server: 8.4.5
- Command: `tests/run_tests.sh`

## Clean build (00 -> 01 -> 02), run twice to show no duplicate accumulation

```text
>> running sql/00_schema.sql
>> running sql/01_load.sql
>> running sql/02_views.sql
+------------+----------+------------+-----------+---------+
| businesses | services | categories | offerings | sources |
+------------+----------+------------+-----------+---------+
|         16 |        7 |          2 |        60 |      21 |
+------------+----------+------------+-----------+---------+
--- second build ---
>> running sql/00_schema.sql
>> running sql/01_load.sql
>> running sql/02_views.sql
+------------+----------+------------+-----------+---------+
| businesses | services | categories | offerings | sources |
+------------+----------+------------+-----------+---------+
|         16 |        7 |          2 |        60 |      21 |
+------------+----------+------------+-----------+---------+
```

## T1 - counts and source-link checks on the real snapshot

Expected: every row PASS.

```text
+--------------------------------------------+--------+--------+
| check_name                                 | actual | result |
+--------------------------------------------+--------+--------+
| businesses >= 15                           |     16 | PASS   |
| service types >= 4                         |      7 | PASS   |
| categories >= 2                            |      2 | PASS   |
| distinct offerings >= 20                   |     60 | PASS   |
| distinct publishers cited >= 2             |     17 | PASS   |
| businesses with missing/invalid source = 0 |      0 | PASS   |
| offerings with missing/invalid source = 0  |      0 | PASS   |
| businesses with zero offerings = 0         |      0 | PASS   |
| foreign_key_checks enabled = 1             |      1 | PASS   |
+--------------------------------------------+--------+--------+
```

## T2 - FK rejects offering with nonexistent business / service

Expected: two ERROR 1452 (foreign key constraint fails); offering count stays 60.

```text
+--------------------------------------------------------------------------+
| step                                                                     |
+--------------------------------------------------------------------------+
| T2a: insert offering for nonexistent business_id 999 (expect ERROR 1452) |
+--------------------------------------------------------------------------+
ERROR 1452 (23000) at line 6: Cannot add or update a child row: a foreign key constraint fails (`p1_car_repair`.`business_service`, CONSTRAINT `fk_bs_business` FOREIGN KEY (`business_id`) REFERENCES `business` (`business_id`) ON DELETE CASCADE ON UPDATE CASCADE)
+------------------------------------------------------------------------+
| step                                                                   |
+------------------------------------------------------------------------+
| T2b: insert offering for nonexistent service_id 99 (expect ERROR 1452) |
+------------------------------------------------------------------------+
ERROR 1452 (23000) at line 9: Cannot add or update a child row: a foreign key constraint fails (`p1_car_repair`.`business_service`, CONSTRAINT `fk_bs_service` FOREIGN KEY (`service_id`) REFERENCES `service` (`service_id`) ON DELETE RESTRICT ON UPDATE CASCADE)
+-------------------------------+-----------+
| step                          | offerings |
+-------------------------------+-----------+
| T2 after: offerings still 60? |        60 |
+-------------------------------+-----------+
```

## T3 - composite PK rejects duplicate business-service pair

Expected: ERROR 1062 Duplicate entry '3-1'; offering count stays 60.

```text
+--------------------------------------------------------------------------------+
| step                                                                           |
+--------------------------------------------------------------------------------+
| T3: insert duplicate pair (3, 1) citing a different source (expect ERROR 1062) |
+--------------------------------------------------------------------------------+
ERROR 1062 (23000) at line 6: Duplicate entry '3-1' for key 'business_service.PRIMARY'
+-------------------------------+-----------+
| step                          | offerings |
+-------------------------------+-----------+
| T3 after: offerings still 60? |        60 |
+-------------------------------+-----------+
```

## T4 - isolated fixture (p1_fixture): absent offering, outer join, missing website, Q3 count

Expected: every check row PASS. The fixture database is dropped afterwards.

```text
+------------------------------------+
| step                               |
+------------------------------------+
| --- Q4 on fixture (NOT EXISTS) --- |
+------------------------------------+
+-------------+------------------+
| business_id | business_name    |
+-------------+------------------+
|         901 | FIXTURE Garage A |
|         902 | FIXTURE Garage B |
+-------------+------------------+
+------------+---------+----------+--------+
| check_name | actual  | expected | result |
+------------+---------+----------+--------+
| Q4 check   | 901,902 | 901,902  | PASS   |
+------------+---------+----------+--------+
+-------------------------------------------------+
| step                                            |
+-------------------------------------------------+
| --- Q5 on fixture (LEFT JOIN, filter in ON) --- |
+-------------------------------------------------+
+------------+-----------------+---------------------+
| service_id | service_name    | matched_business_id |
+------------+-----------------+---------------------+
|          1 | Oil Change      |                 902 |
|          2 | Tire Service    |                NULL |
|          3 | Wheel Alignment |                NULL |
+------------+-----------------+---------------------+
+------------+---------------------+---------------------+--------+
| check_name | actual              | expected            | result |
+------------+---------------------+---------------------+--------+
| Q5 check   | 1:902,2:NULL,3:NULL | 1:902,2:NULL,3:NULL | PASS   |
+------------+---------------------+---------------------+--------+
+-----------------------------------------------------------+---------------+------------------------------------+
| check_name                                                | rows_returned | note                               |
+-----------------------------------------------------------+---------------+------------------------------------+
| Q5 wrong-placement demo (filter in WHERE drops NULL rows) |             1 | fewer than 3 rows = NULL rows lost |
+-----------------------------------------------------------+---------------+------------------------------------+
+----------------------------------------+
| step                                   |
+----------------------------------------+
| --- Q6 on fixture (view + IS NULL) --- |
+----------------------------------------+
+-------------+------------------+---------+
| business_id | business_name    | city    |
+-------------+------------------+---------+
|         901 | FIXTURE Garage A | Chicago |
+-------------+------------------+---------+
+------------+--------+----------+--------+
| check_name | actual | expected | result |
+------------+--------+----------+--------+
| Q6 check   | 901    | 901      | PASS   |
+------------+--------+----------+--------+
+---------------------------------------+
| step                                  |
+---------------------------------------+
| --- Q3 on fixture vs manual count --- |
+---------------------------------------+
+--------------+----------------+
| service_name | provider_count |
+--------------+----------------+
| Oil Change   |              3 |
| Tire Service |              2 |
+--------------+----------------+
+------------+-----------------------------+-----------------------------+--------+
| check_name | actual                      | expected                    | result |
+------------+-----------------------------+-----------------------------+--------+
| Q3 check   | Oil Change=3,Tire Service=2 | Oil Change=3,Tire Service=2 | PASS   |
+------------+-----------------------------+-----------------------------+--------+
p1_fixture dropped.
```

## Post-test: real snapshot is unchanged and uncontaminated

```text
+------------+-----------+--------------+-------------------+
| businesses | offerings | fixture_rows | fixture_db_exists |
+------------+-----------+--------------+-------------------+
|         16 |        60 |            0 |                 0 |
+------------+-----------+--------------+-------------------+
```
