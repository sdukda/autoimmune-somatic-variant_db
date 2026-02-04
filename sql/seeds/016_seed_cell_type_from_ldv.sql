USE autoimmune_db;

-- Create/populate the cell_type lookup table from what appears in literature_driver_variants
-- (Only inserts new names; safe to re-run.)
INSERT INTO cell_type (cell_type_name)
SELECT DISTINCT ldv.cell_type_name
FROM literature_driver_variants ldv
WHERE ldv.cell_type_name IS NOT NULL
  AND TRIM(ldv.cell_type_name) <> ''
ON DUPLICATE KEY UPDATE
  cell_type_name = VALUES(cell_type_name);
