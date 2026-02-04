-- 008_create_view_literature_summary_by_gene.sql
-- Purpose:
--   Summary stats per gene across all literature variants + evidence links.
--   Uses literature_variant_study as the evidence/provenance layer.
--   "analysis-ready v1" view.

DROP VIEW IF EXISTS v_literature_summary_by_gene;

CREATE VIEW v_literature_summary_by_gene AS
SELECT
  ldv.gene_symbol,
  COUNT(DISTINCT ldv.literature_variant_id)          AS n_unique_variants,
  COUNT(DISTINCT lvs.study_id)                       AS n_studies,
  COUNT(DISTINCT ldv.disease_id)                     AS n_diseases,
  COUNT(*)                                           AS n_evidence_links
FROM literature_variant_study lvs
JOIN literature_driver_variants ldv
  ON ldv.literature_variant_id = lvs.literature_variant_id
GROUP BY ldv.gene_symbol;
