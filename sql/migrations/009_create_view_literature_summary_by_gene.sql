-- 009_create_view_literature_summary_by_gene.sql
-- Summary of literature variants grouped by gene

CREATE OR REPLACE VIEW v_literature_summary_by_gene AS
SELECT
  ldv.gene_symbol,
  COUNT(DISTINCT ldv.literature_variant_id) AS n_unique_variants,
  COUNT(DISTINCT lvs.study_id)              AS n_studies,
  COUNT(DISTINCT ldv.disease_id)             AS n_diseases
FROM literature_driver_variants ldv
LEFT JOIN literature_variant_study lvs
  ON lvs.literature_variant_id = ldv.literature_variant_id
GROUP BY ldv.gene_symbol;
