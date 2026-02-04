-- 022_add_variant_type_norm.sql

ALTER TABLE literature_driver_variants
  ADD COLUMN variant_type_norm VARCHAR(16) NULL AFTER variant_type;

-- Backfill: compute atomic type from ref/alt (prefer lifted, else paper)
UPDATE literature_driver_variants
SET variant_type_norm =
  CASE
    WHEN COALESCE(lifted_ref, paper_ref) IS NULL
      OR COALESCE(lifted_alt, paper_alt) IS NULL
      OR COALESCE(lifted_ref, paper_ref) = ''
      OR COALESCE(lifted_alt, paper_alt) = '' THEN NULL

    WHEN COALESCE(lifted_ref, paper_ref) = '-' AND COALESCE(lifted_alt, paper_alt) <> '-' THEN 'Insertion'
    WHEN COALESCE(lifted_alt, paper_alt) = '-' AND COALESCE(lifted_ref, paper_ref) <> '-' THEN 'Deletion'

    WHEN CHAR_LENGTH(COALESCE(lifted_ref, paper_ref)) = 1
     AND CHAR_LENGTH(COALESCE(lifted_alt, paper_alt)) = 1 THEN 'SNV'

    WHEN CHAR_LENGTH(COALESCE(lifted_ref, paper_ref)) < CHAR_LENGTH(COALESCE(lifted_alt, paper_alt)) THEN 'Insertion'
    WHEN CHAR_LENGTH(COALESCE(lifted_ref, paper_ref)) > CHAR_LENGTH(COALESCE(lifted_alt, paper_alt)) THEN 'Deletion'

    WHEN CHAR_LENGTH(COALESCE(lifted_ref, paper_ref)) > 1
     AND CHAR_LENGTH(COALESCE(lifted_alt, paper_alt)) > 1 THEN 'MNV'

    ELSE 'Indel'
  END;

-- Enforce atomic type only on variant_type_norm
ALTER TABLE literature_driver_variants
  ADD CONSTRAINT chk_ldv_variant_type_norm_atomic
  CHECK (
    variant_type_norm IS NULL
    OR variant_type_norm IN ('SNV','Insertion','Deletion','Indel','MNV')
  );
