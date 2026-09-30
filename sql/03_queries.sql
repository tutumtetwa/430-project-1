-- =====================================================================
-- 03_queries.sql  --  Q1-Q6 against the real snapshot
-- Parameters are set with user variables at the top of each query so a
-- presenter can change one value and re-run.
-- =====================================================================
USE p1_car_repair;

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

-- ---------------------------------------------------------------------
-- Q6. Which businesses in the directory view have no recorded website?
--     Uses v_business_directory from 02_views.sql.
--     Output: business_id, business_name, city
-- ---------------------------------------------------------------------
SELECT  business_id, business_name, city
FROM    v_business_directory
WHERE   website IS NULL
ORDER BY business_name, business_id;
