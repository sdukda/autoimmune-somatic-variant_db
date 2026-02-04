ALTER TABLE literature_driver_variants
  ADD CONSTRAINT chk_ldv_variant_type_atomic
  CHECK (
    variant_type IS NULL
    OR variant_type IN ('SNV','Insertion','Deletion','Indel','MNV')
  );

ALTER TABLE literature_driver_variants
  ADD CONSTRAINT chk_ldv_variant_type_atomic
  CHECK (
    variant_type IS NULL
    OR variant_type IN ('SNV','Insertion','Deletion','Indel','MNV')
  );
