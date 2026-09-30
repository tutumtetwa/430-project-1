-- T1. Minimum counts and source-link integrity on the REAL snapshot.
-- Every row prints expected vs actual and PASS/FAIL. Fixtures never live in
-- p1_car_repair (T4 uses a separate database), so nothing synthetic is counted.
USE p1_car_repair;

SELECT 'businesses >= 15' AS check_name, COUNT(*) AS actual,
       IF(COUNT(*) >= 15, 'PASS', 'FAIL') AS result FROM business
UNION ALL
SELECT 'service types >= 4', COUNT(*), IF(COUNT(*) >= 4, 'PASS', 'FAIL') FROM service
UNION ALL
SELECT 'categories >= 2', COUNT(*), IF(COUNT(*) >= 2, 'PASS', 'FAIL') FROM service_category
UNION ALL
SELECT 'distinct offerings >= 20', COUNT(DISTINCT business_id, service_id),
       IF(COUNT(DISTINCT business_id, service_id) >= 20, 'PASS', 'FAIL') FROM business_service
UNION ALL
SELECT 'distinct publishers cited >= 2', COUNT(DISTINCT s.publisher),
       IF(COUNT(DISTINCT s.publisher) >= 2, 'PASS', 'FAIL')
FROM source s
WHERE s.source_id IN (SELECT source_id FROM business UNION SELECT source_id FROM business_service)
UNION ALL
SELECT 'businesses with missing/invalid source = 0', COUNT(*), IF(COUNT(*) = 0, 'PASS', 'FAIL')
FROM business b LEFT JOIN source s ON s.source_id = b.source_id
WHERE s.source_id IS NULL OR b.raw_row_ref NOT LIKE 'LIC:%'
UNION ALL
SELECT 'offerings with missing/invalid source = 0', COUNT(*), IF(COUNT(*) = 0, 'PASS', 'FAIL')
FROM business_service bs LEFT JOIN source s ON s.source_id = bs.source_id
WHERE s.source_id IS NULL OR bs.raw_row_ref NOT LIKE 'OBS:%'
UNION ALL
SELECT 'businesses with zero offerings = 0', COUNT(*), IF(COUNT(*) = 0, 'PASS', 'FAIL')
FROM business b
WHERE NOT EXISTS (SELECT 1 FROM business_service bs WHERE bs.business_id = b.business_id)
UNION ALL
SELECT 'foreign_key_checks enabled = 1', @@foreign_key_checks,
       IF(@@foreign_key_checks = 1, 'PASS', 'FAIL');
