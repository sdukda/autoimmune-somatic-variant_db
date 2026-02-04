-- 010_create_view_literature_summary_by_disease.sql
-- Summary of literature variants grouped by disease

CREATE OR REPLACE VIEW v_literature_summary_by_disease AS
SELECT
  d.disease_id,
  d.disease_name,
  COUNT(DISTINCT ldv.literature_variant_id) AS n_unique_variants,
  COUNT(DISTINCT lvs.study_id)              AS n_studies,
  COUNT(DISTINCT ldv.gene_symbol)           AS n_genes
FROM disease d
LEFT JOIN literature_driver_variants ldv
  ON ldv.disease_id = d.disease_id
LEFT JOIN literature_variant_study lvs
  ON lvs.literature_variant_id = ldv.literature_variant_id
GROUP BY d.disease_id, d.disease_name;
