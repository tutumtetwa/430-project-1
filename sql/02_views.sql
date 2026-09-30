-- =====================================================================
-- 02_views.sql  --  reusable directory view (used by Q6)
-- Run after 00_schema.sql and 01_load.sql.
-- =====================================================================
USE p1_car_repair;

-- One row per business: its selected location, website (NULL if none
-- recorded), and how many distinct services are recorded for it.
-- LEFT JOIN keeps businesses even if they have zero recorded offerings.
CREATE OR REPLACE VIEW v_business_directory AS
SELECT  b.business_id,
        b.business_name,
        b.street_address,
        b.city,
        b.neighborhood,
        b.website,
        COUNT(DISTINCT bs.service_id) AS offering_count
FROM    business b
LEFT JOIN business_service bs ON bs.business_id = b.business_id
GROUP BY b.business_id, b.business_name, b.street_address, b.city,
         b.neighborhood, b.website;
