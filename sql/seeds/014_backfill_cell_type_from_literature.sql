USE autoimmune_db;

INSERT INTO cell_type (cell_type_name)
SELECT DISTINCT TRIM(cell_type_name)
FROM literature_driver_variants
WHERE cell_type_name IS NOT NULL
  AND TRIM(cell_type_name) <> '';
