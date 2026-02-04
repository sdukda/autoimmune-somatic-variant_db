-- 005_freeze_analysis_ready_v1.sql
-- Purpose: create immutable analysis snapshots + optional views pointing to them

USE autoimmune_db;

-- 1) Create snapshot tables (drop if re-running intentionally)
DROP TABLE IF EXISTS literature_driver_variants_v1_snapshot;
DROP TABLE IF EXISTS literature_variant_study_v1_snapshot;

CREATE TABLE literature_driver_variants_v1_snapshot AS
SELECT * FROM literature_driver_variants;

CREATE TABLE literature_variant_study_v1_snapshot AS
SELECT * FROM literature_variant_study;

-- 2) Add useful indexes on snapshots (optional but recommended)
ALTER TABLE literature_driver_variants_v1_snapshot
  ADD PRIMARY KEY (literature_variant_id),
  ADD INDEX idx_ldv_v1_gene (gene_symbol),
  ADD INDEX idx_ldv_v1_disease (disease_id),
  ADD UNIQUE KEY uq_ldv_v1_natural_hash (natural_key_sha);

ALTER TABLE literature_variant_study_v1_snapshot
  ADD PRIMARY KEY (literature_variant_study_id),
  ADD INDEX idx_lvs_v1_variant (literature_variant_id),
  ADD INDEX idx_lvs_v1_study (study_id),
  ADD UNIQUE KEY uq_lvs_v1_variant_study (literature_variant_id, study_id);

-- 3) Optional: views that always point to the v1 snapshot
CREATE OR REPLACE VIEW v1_literature_driver_variants AS
SELECT * FROM literature_driver_variants_v1_snapshot;

CREATE OR REPLACE VIEW v1_literature_variant_study AS
SELECT * FROM literature_variant_study_v1_snapshot;
