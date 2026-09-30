-- T2. Foreign keys must reject offerings that reference a nonexistent
-- business or service. EXPECTED: both INSERTs fail with ERROR 1452.
-- Run with `mysql --force` so the second statement still executes.
USE p1_car_repair;
SELECT 'T2a: insert offering for nonexistent business_id 999 (expect ERROR 1452)' AS step;
INSERT INTO business_service (business_id, service_id, source_id, raw_row_ref, observed_wording)
VALUES (999, 1, 'SRC02', 'OBS:TEST', 'test row');
SELECT 'T2b: insert offering for nonexistent service_id 99 (expect ERROR 1452)' AS step;
INSERT INTO business_service (business_id, service_id, source_id, raw_row_ref, observed_wording)
VALUES (1, 99, 'SRC02', 'OBS:TEST', 'test row');
SELECT 'T2 after: offerings still 60?' AS step, COUNT(*) AS offerings FROM business_service;
