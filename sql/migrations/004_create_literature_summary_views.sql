-- 004_create_literature_summary_views.sql
-- Purpose: analysis views over literature_driver_variants + literature_variant_study

USE autoimmune_db;


-- A) Study-level summaries

CREATE OR REPLACE VIEW v_literature_summary_by_study AS
SELECT
  s.study_id,
  s.study_name,
  COUNT(DISTINCT lvs.literature_variant_id)                 AS n_unique_variants,
  COUNT(*)                                                  AS n_evidence_links,
  COUNT(DISTINCT ldv.gene_symbol)                           AS n_genes,
  COUNT(DISTINCT ldv.disease_id)                            AS n_diseases,
  MIN(lvs.created_at)                                       AS first_linked_at,
  MAX(lvs.created_at)                                       AS last_linked_at
FROM study s
LEFT JOIN literature_variant_study lvs
  ON lvs.study_id = s.study_id
LEFT JOIN literature_driver_variants ldv
  ON ldv.literature_variant_id = lvs.literature_variant_id
GROUP BY s.study_id, s.study_name;


-- B) Gene-level summaries (all studies)

CREATE OR REPLACE VIEW v_literature_summary_by_gene AS
SELECT
  ldv.gene_symbol,
  COUNT(DISTINCT lvs.study_id)                              AS n_studies,
  COUNT(DISTINCT ldv.literature_variant_id)                 AS n_unique_variants,
  COUNT(*)                                                  AS n_evidence_links,
  COUNT(DISTINCT ldv.disease_id)                            AS n_diseases
FROM literature_driver_variants ldv
JOIN literature_variant_study lvs
  ON lvs.literature_variant_id = ldv.literature_variant_id
GROUP BY ldv.gene_symbol;


-- C) Study x Gene matrix (handy for quick checks)

CREATE OR REPLACE VIEW v_literature_study_gene AS
SELECT
  s.study_id,
  s.study_name,
  ldv.gene_symbol,
  COUNT(DISTINCT ldv.literature_variant_id)                 AS n_unique_variants,
  COUNT(*)                                                  AS n_evidence_links
FROM study s
JOIN literature_variant_study lvs
  ON lvs.study_id = s.study_id
JOIN literature_driver_variants ldv
  ON ldv.literature_variant_id = lvs.literature_variant_id
GROUP BY s.study_id, s.study_name, ldv.gene_symbol;


-- D) Disease-level summaries (optional)

CREATE OR REPLACE VIEW v_literature_summary_by_disease AS
SELECT
  d.disease_id,
  d.disease_name,
  COUNT(DISTINCT lvs.study_id)                              AS n_studies,
  COUNT(DISTINCT ldv.literature_variant_id)                 AS n_unique_variants,
  COUNT(DISTINCT ldv.gene_symbol)                           AS n_genes,
  COUNT(*)                                                  AS n_evidence_links
FROM disease d
JOIN literature_driver_variants ldv
  ON ldv.disease_id = d.disease_id
JOIN literature_variant_study lvs
  ON lvs.literature_variant_id = ldv.literature_variant_id
GROUP BY d.disease_id, d.disease_name;

