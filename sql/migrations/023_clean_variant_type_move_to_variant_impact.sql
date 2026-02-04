-- 023_clean_variant_type_move_to_variant_impact.sql
-- Purpose:
-- 1) If variant_impact is empty, move legacy mixed "variant_type" text into variant_impact
-- 2) Set variant_type to the atomic class computed in variant_type_norm
-- 3) (Optional but helpful) normalise variant_impact a bit (remove "(LoF)" etc.)

START TRANSACTION;

-- 1) Move legacy mixed strings into variant_impact (only when variant_impact is empty)
UPDATE literature_driver_variants
SET variant_impact = TRIM(variant_type)
WHERE (variant_impact IS NULL OR TRIM(variant_impact) = '' OR TRIM(variant_impact) = '.')
  AND variant_type IS NOT NULL
  AND TRIM(variant_type) <> ''
  AND TRIM(variant_type) <> '.'
  AND TRIM(variant_type) NOT IN ('SNV','Insertion','Deletion','Indel','MNV');

-- 2) Now force variant_type to be atomic (from variant_type_norm)
UPDATE literature_driver_variants
SET variant_type = variant_type_norm
WHERE variant_type_norm IS NOT NULL;

-- 3) Optional light cleanup: if variant_type_norm is NULL, but variant_type currently has an atomic value, keep it
UPDATE literature_driver_variants
SET variant_type_norm = variant_type
WHERE variant_type_norm IS NULL
  AND variant_type IN ('SNV','Insertion','Deletion','Indel','MNV');

-- 4) Optional: normalise variant_impact text a little (remove parenthetical notes like "(LoF)")
UPDATE literature_driver_variants
SET variant_impact = TRIM(REGEXP_REPLACE(variant_impact, '\\s*\\(.*\\)\\s*', ''))
WHERE variant_impact IS NOT NULL
  AND TRIM(variant_impact) <> ''
  AND variant_impact REGEXP '\\(.*\\)';

COMMIT;
