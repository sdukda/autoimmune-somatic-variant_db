USE autoimmune_db;

-- 1. Add new columns that turn sample_variant_1 into an actual per-call evidence table.

ALTER TABLE sample_variant_1
    ADD COLUMN sample_id BIGINT NULL AFTER cell_id,
    ADD COLUMN ad_ref INT NULL AFTER variant_id,
    ADD COLUMN ad_alt INT NULL AFTER ad_ref,
    ADD COLUMN gq INT NULL AFTER ad_ref,
    ADD COLUMN filters VARCHAR(64) NULL AFTER ad_ref,
    ADD COLUMN update_at TIMESTAMP NOT NULL
    DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP
    AFTER filters;

-- Meaning of these columns:
--   sample_id : which biological sample this call belongs to
--               (NULL allowed for purely single-cell usage if you only have cell_id)
--   ad_ref    : depth (number of reads) supporting the REF allele
--   ad_alt    : depth (number of reads) supporting the ALT allele
--   gq        : genotype quality score for this call
--   filters   : pipeline filter decision (e.g. 'PASS', 'LowQual', etc.)
--   updated_at: bookkeeping/refresh timestamp

ALTER TABLE sample_variant_1
    ADD INDEX idx_sv1_sample_id (sample_id),
    ADD INDEX idx_sv1_variant_id (variant_id),
    ADD INDEX idx_sv1_cell_id    (cell_id);

-- If you get "Duplicate key name" errors here while running,
-- just DROP those lines and re-run. It's safe.


-- 3. Add FK from sample_variant_1.sample_id -> sample.sample_id
--    We already know from your FK dump that:
--      fk_sv1_cell     (cell_id -> cell.cell_id) exists
--      fk_sv1_variant  (variant_id -> variants.variant_id) exists
--    sample_id FK didn't exist before. We'll add it.

ALTER TABLE sample_variant_1
    ADD CONSTRAINT fk_sv1_sample
    FOREIGN KEY (sample_id)
    REFERENCES sample(sample_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE;



