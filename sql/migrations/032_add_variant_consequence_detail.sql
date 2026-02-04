ALTER TABLE literature_driver_variants
  ADD COLUMN variant_consequence_detail VARCHAR(128) NULL
  AFTER variant_impact;
