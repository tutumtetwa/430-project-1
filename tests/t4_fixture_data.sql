-- T4 fixture data. Loaded ONLY into the isolated database p1_fixture
-- (created by run_tests.sh from the same 00_schema.sql / 02_views.sql).
-- Synthetic, clearly labeled records; never loaded into p1_car_repair.
--   Garage A (901): NO website; offers Oil Change + Tire Service
--   Garage B (902): website;    offers Oil Change only
--   Garage C (903): website;    offers Oil Change + Tire Service + Wheel Alignment
INSERT INTO source VALUES
  ('FIX01', 'FIXTURE (synthetic)', 'Synthetic test fixture', 'fixture://t4', '2026-09-30', 'tests/t4_fixture_data.sql');
INSERT INTO service_category VALUES (1, 'Routine Maintenance'), (2, 'Repair & Diagnostics');
INSERT INTO service VALUES (1, 'Oil Change', 1), (2, 'Tire Service', 1), (3, 'Wheel Alignment', 1);
INSERT INTO business VALUES
  (901, 'FIXTURE Garage A', '1 Test St', 'Chicago', 'IL', '60601', 'Test', NULL,                'FIX01', 'FIXTURE:A'),
  (902, 'FIXTURE Garage B', '2 Test St', 'Chicago', 'IL', '60601', 'Test', 'https://b.example', 'FIX01', 'FIXTURE:B'),
  (903, 'FIXTURE Garage C', '3 Test St', 'Chicago', 'IL', '60601', 'Test', 'https://c.example', 'FIX01', 'FIXTURE:C');
INSERT INTO business_service VALUES
  (901, 1, 'FIX01', 'FIXTURE:A1', 'oil'),
  (901, 2, 'FIX01', 'FIXTURE:A2', 'tires'),
  (902, 1, 'FIX01', 'FIXTURE:B1', 'oil'),
  (903, 1, 'FIX01', 'FIXTURE:C1', 'oil'),
  (903, 2, 'FIX01', 'FIXTURE:C2', 'tires'),
  (903, 3, 'FIX01', 'FIXTURE:C3', 'alignment');
