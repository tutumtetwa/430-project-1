-- T3. The composite primary key must reject a duplicate business-service
-- pair. Bucaro Brothers (3) already has Oil Change (1).
-- EXPECTED: ERROR 1062 Duplicate entry '3-1' for key 'business_service.PRIMARY'.
USE p1_car_repair;
SELECT 'T3: insert duplicate pair (3, 1) citing a different source (expect ERROR 1062)' AS step;
INSERT INTO business_service (business_id, service_id, source_id, raw_row_ref, observed_wording)
VALUES (3, 1, 'SRC01', 'OBS:TEST', 'duplicate citation of oil change');
SELECT 'T3 after: offerings still 60?' AS step, COUNT(*) AS offerings FROM business_service;
