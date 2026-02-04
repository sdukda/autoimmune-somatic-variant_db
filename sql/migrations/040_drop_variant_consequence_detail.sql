-- 040_drop_variant_consequence_detail.sql
USE autoimmune_db;

ALTER TABLE literature_driver_variants
DROP COLUMN variant_consequence_detail;
