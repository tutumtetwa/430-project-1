-- T4 checks: run the SAME logic as Q3-Q6 against the fixture and compare
-- with hand-derived expectations.
--   Q4 (@service='Wheel Alignment') expected: 901, 902   (absent offering)
--   Q5 (@business_id=902) expected: Oil Change->902, Tire Service->NULL, Wheel Alignment->NULL
--   Q6 expected: 901 only (missing website)
--   Q3 (@min_providers=2) expected: Oil Change=3, Tire Service=2 (manual count of fixture rows)

SELECT '--- Q4 on fixture (NOT EXISTS) ---' AS step;
SET @service = 'Wheel Alignment';
SELECT b.business_id, b.business_name
FROM business b
WHERE NOT EXISTS (SELECT 1 FROM business_service bs JOIN service s ON s.service_id = bs.service_id
                  WHERE bs.business_id = b.business_id AND s.service_name = @service)
ORDER BY b.business_name;
SELECT 'Q4 check' AS check_name,
       GROUP_CONCAT(b.business_id ORDER BY b.business_id) AS actual, '901,902' AS expected,
       IF(GROUP_CONCAT(b.business_id ORDER BY b.business_id) = '901,902', 'PASS', 'FAIL') AS result
FROM business b
WHERE NOT EXISTS (SELECT 1 FROM business_service bs JOIN service s ON s.service_id = bs.service_id
                  WHERE bs.business_id = b.business_id AND s.service_name = @service);

SELECT '--- Q5 on fixture (LEFT JOIN, filter in ON) ---' AS step;
SET @business_id = 902;
SELECT s.service_id, s.service_name, bs.business_id AS matched_business_id
FROM service s
LEFT JOIN business_service bs ON bs.service_id = s.service_id AND bs.business_id = @business_id
ORDER BY s.service_id;
SELECT 'Q5 check' AS check_name,
       GROUP_CONCAT(CONCAT(s.service_id, ':', IFNULL(bs.business_id, 'NULL')) ORDER BY s.service_id) AS actual,
       '1:902,2:NULL,3:NULL' AS expected,
       IF(GROUP_CONCAT(CONCAT(s.service_id, ':', IFNULL(bs.business_id, 'NULL')) ORDER BY s.service_id)
          = '1:902,2:NULL,3:NULL', 'PASS', 'FAIL') AS result
FROM service s
LEFT JOIN business_service bs ON bs.service_id = s.service_id AND bs.business_id = @business_id;
SELECT 'Q5 wrong-placement demo (filter in WHERE drops NULL rows)' AS check_name,
       COUNT(*) AS rows_returned, 'fewer than 3 rows = NULL rows lost' AS note
FROM service s
LEFT JOIN business_service bs ON bs.service_id = s.service_id
WHERE bs.business_id = @business_id;

SELECT '--- Q6 on fixture (view + IS NULL) ---' AS step;
SELECT business_id, business_name, city FROM v_business_directory WHERE website IS NULL ORDER BY business_name;
SELECT 'Q6 check' AS check_name,
       GROUP_CONCAT(business_id) AS actual, '901' AS expected,
       IF(GROUP_CONCAT(business_id) = '901', 'PASS', 'FAIL') AS result
FROM v_business_directory WHERE website IS NULL;

SELECT '--- Q3 on fixture vs manual count ---' AS step;
SET @min_providers = 2;
SELECT s.service_name, COUNT(DISTINCT bs.business_id) AS provider_count
FROM service s JOIN business_service bs ON bs.service_id = s.service_id
GROUP BY s.service_id, s.service_name
HAVING COUNT(DISTINCT bs.business_id) >= @min_providers
ORDER BY provider_count DESC, s.service_name;
SELECT 'Q3 check' AS check_name,
       GROUP_CONCAT(CONCAT(t.service_name, '=', t.provider_count) ORDER BY t.service_name) AS actual,
       'Oil Change=3,Tire Service=2' AS expected,
       IF(GROUP_CONCAT(CONCAT(t.service_name, '=', t.provider_count) ORDER BY t.service_name)
          = 'Oil Change=3,Tire Service=2', 'PASS', 'FAIL') AS result
FROM (SELECT s.service_name, COUNT(DISTINCT bs.business_id) AS provider_count
      FROM service s JOIN business_service bs ON bs.service_id = s.service_id
      GROUP BY s.service_id, s.service_name
      HAVING COUNT(DISTINCT bs.business_id) >= @min_providers) t;
