USE autoimmune_db;
-- 1. Relax NULLability in sample_annotation
--    Make variant_id and disease_id nullable so we can store
--    sample-level annotations (batch, diagnosis, etc.) that
--    are not tied to a specific variant or disease row.
ALTER TABLE sample_annotation
  MODIFY COLUMN variant_id BIGINT NULL,
  MODIFY COLUMN disease_id BIGINT NULL;

-- (FKs can stay the same: ON DELETE SET NULL already matches this.)



-- 2. Add prediction columns directly to variant_annotation
--    so we don't need a separate annotation_prediction table.
--    Only run these ADD COLUMN if they don't already exist in your live DB.
ALTER TABLE variant_annotation
  ADD COLUMN polyphen_pred  VARCHAR(32) NULL AFTER hgvsp,
  ADD COLUMN polyphen_score DECIMAL(4,3) NULL AFTER polyphen_pred;
  -- polyphen_pred: e.g. 'benign', 'possibly_damaging'
  -- polyphen_score: numeric score like 0.912


-- 3. Drop tables we no longer want to maintain separately
--    (safe because we merged or decided they’re not critical for v1).
DROP TABLE IF EXISTS annotation_prediction;
DROP TABLE IF EXISTS study_variant;
DROP TABLE IF EXISTS gene_synonym;
DROP TABLE IF EXISTS disease_synonym;
DROP TABLE IF EXISTS gene_overlap;
DROP TABLE IF EXISTS external_annotation;

-- If you also decided variant_freq is not needed right now, uncomment:
-- DROP TABLE IF EXISTS variant_freq;

-- NOTE: we are NOT dropping somatic. We KEEP somatic because it
--       encodes whether a variant is interpreted as somatic / germline
--       in the autoimmune context.
