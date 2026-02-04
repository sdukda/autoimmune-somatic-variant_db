USE autoimmune_db;

CREATE OR REPLACE VIEW v_literature_summary_by_study AS
SELECT
  s.study_id,
  s.study_name,
  COUNT(DISTINCT lvs.literature_variant_id) AS n_unique_variants,
  COUNT(*)                                  AS n_evidence_links,
  COUNT(DISTINCT ldv.gene_symbol)           AS n_genes,
  COUNT(DISTINCT ldv.disease_id)            AS n_diseases
FROM study s
LEFT JOIN literature_variant_study lvs
  ON lvs.study_id = s.study_id
LEFT JOIN literature_driver_variants ldv
  ON ldv.literature_variant_id = lvs.literature_variant_id
GROUP BY s.study_id, s.study_name;

CREATE OR REPLACE VIEW v_literature_summary_by_gene AS
SELECT
  ldv.gene_symbol,
  COUNT(DISTINCT lvs.study_id)              AS n_studies,
  COUNT(DISTINCT ldv.literature_variant_id) AS n_unique_variants,
  COUNT(*)                                  AS n_evidence_links,
  COUNT(DISTINCT ldv.disease_id)            AS n_diseases
FROM literature_driver_variants ldv
JOIN literature_variant_study lvs
  ON lvs.literature_variant_id = ldv.literature_variant_id
GROUP BY ldv.gene_symbol;

CREATE OR REPLACE VIEW v_literature_study_gene AS
SELECT
  s.study_id,
  s.study_name,
  ldv.gene_symbol,
  COUNT(DISTINCT ldv.literature_variant_id) AS n_unique_variants,
  COUNT(*)                                  AS n_evidence_links
FROM study s
JOIN literature_variant_study lvs
  ON lvs.study_id = s.study_id
JOIN literature_driver_variants ldv
  ON ldv.literature_variant_id = lvs.literature_variant_id
GROUP BY s.study_id, s.study_name, ldv.gene_symbol;


