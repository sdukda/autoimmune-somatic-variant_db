USE autoimmune_db;

-- 1. Rename table to a biologically meaningful name

RENAME TABLE sample_variant_1 TO sample_variant_call;

-- 2. Clean up FK names to be readable / future-proof.
--    We'll drop the old constraint names (fk_sv1_cell, fk_sv1_variant, fk_sv1_sample)
--    and recreate them with new names that use 'svc' (sample_variant_call).
--
-- BUT: if you don't know the exact current FK names in your DB, you can first inspect them:
--   SELECT CONSTRAINT_NAME
--   FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
--   WHERE TABLE_SCHEMA = DATABASE()
--     AND TABLE_NAME = 'sample_variant_call'
--     AND REFERENCED_TABLE_NAME IS NOT NULL;
--
-- After you confirm the names, run the block below with correct DROP FOREIGN KEY lines.

ALTER TABLE sample_variant_call
  DROP FOREIGN KEY fk_sv1_cell,
  DROP FOREIGN KEY fk_sv1_variant,
  DROP FOREIGN KEY fk_sv1_sample;

ALTER TABLE sample_variant_call
  ADD CONSTRAINT fk_svc_cell
    FOREIGN KEY (cell_id)
    REFERENCES cell(cell_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,

  ADD CONSTRAINT fk_svc_sample
    FOREIGN KEY (sample_id)
    REFERENCES sample(sample_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,

  ADD CONSTRAINT fk_svc_variant
    FOREIGN KEY (variant_id)
    REFERENCES variants(variant_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE;

-- 3. (Optional but very helpful) add a uniqueness rule
--    This prevents storing the same call twice.
--    Logic: within the same (sample_id, cell_id, variant_id) combination,
--    you should only have one row.
--
--    We allow NULLs in sample_id or cell_id, so this UNIQUE won't always collapse
--    everything, but it's already a huge improvement.
--
--    If this errors with "Duplicate entry", it means you already have true duplicates.
--    You can skip it for now and revisit later.

ALTER TABLE sample_variant_call
  ADD UNIQUE KEY uq_svc_call (sample_id, cell_id, variant_id);

