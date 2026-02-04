USE autoimmune_db;

DROP TABLE IF EXISTS literature_driver_variants_v1_snapshot;
DROP TABLE IF EXISTS literature_variant_study_v1_snapshot;

CREATE TABLE literature_driver_variants_v1_snapshot AS
SELECT * FROM literature_driver_variants;

CREATE TABLE literature_variant_study_v1_snapshot AS
SELECT * FROM literature_variant_study;

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

CREATE OR REPLACE VIEW v1_literature_driver_variants AS
SELECT * FROM literature_driver_variants_v1_snapshot;

CREATE OR REPLACE VIEW v1_literature_variant_study AS
SELECT * FROM literature_variant_study_v1_snapshot;
