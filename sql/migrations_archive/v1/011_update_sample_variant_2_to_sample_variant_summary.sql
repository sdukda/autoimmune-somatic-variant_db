USE autoimmune_db;

-- 1. Rename the table from the generic/temporary name
--    to the biology-accurate name.
RENAME TABLE sample_variant_2 TO sample_variant_summary;

ALTER TABLE sample_variant_summary
    DROP COLUMN genotype,
    DROP COLUMN dp,
    DROP COLUMN gq;

-- 2. Add the single-cell summary fields.

ALTER TABLE sample_variant_summary
    ADD COLUMN num_cell_pos INT NOT NULL DEFAULT 0 AFTER variant_id,
    ADD COLUMN presence_cell TINYINT(1) NOT NULL DEFAULT 0 AFTER num_cell_pos,
    ADD COLUMN qc_status VARCHAR(32) NULL AFTER presence_cell,
    ADD COLUMN updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP
    AFTER qc_status;

-- num_cell_pos: how many cells in this sample carried this variant
-- presence_cell: 1 if seen in at least one cell, else 0
-- qc_status: your interpretation label ('PASS', 'suspect', etc.)
-- updated_at: bookkeeping

-- 3. Make sure we still have indexes on the FKs for joins.
--    These should exist already, but it's okay to add them if they don't.
--    If adding these causes "Duplicate key name" errors,
--    comment out the ones that already exist and rerun those lines manually.

ALTER TABLE sample_variant_summary
  ADD INDEX idx_svsum_sample (sample_id),
  ADD INDEX idx_svsum_variant (variant_id);

-- 4. The original foreign keys from sample_variant_2 should still be in place:
--    fk_sv2_sample   sample_variant_2.sample_id   -> sample.sample_id
--    fk_sv2_variant  sample_variant_2.variant_id  -> variants.variant_id
--
--    After the RENAME they will now refer to sample_variant_summary
--    but MySQL will keep their old names (fk_sv2_sample, fk_sv2_variant).
--    You can leave those names as-is. They still enforce referential integrity.
--
--    If you want pretty names that match the new table,
--    you can do that later in a follow-up migration the same
--    way we planned for sample_variant_call, e.g.:
--      - DROP FOREIGN KEY fk_sv2_sample
--      - DROP FOREIGN KEY fk_sv2_variant
--      - re-ADD them as fk_svsum_sample and fk_svsum_variant.
--
--    That's cosmetic and can wait.

