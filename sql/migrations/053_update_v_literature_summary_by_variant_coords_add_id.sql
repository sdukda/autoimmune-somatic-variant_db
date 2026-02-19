DROP VIEW IF EXISTS v_literature_summary_by_variant_coords;

CREATE VIEW v_literature_summary_by_variant_coords AS
SELECT
  -- existing grouping keys
  gene_symbol,
  lifted_ref_genome AS ref_genome,
  genomic_variant,

  -- NEW: keep a stable ID we can link to
  MIN(literature_variant_id) AS example_literature_variant_id,

  -- NEW: display-friendly fallback
  MAX(protein_change) AS protein_change,

  -- existing outputs
  COALESCE(consequence, 'Unknown') AS consequence,
  COUNT(*) AS n_reports,
  COUNT(DISTINCT study_id) AS n_studies,
  GROUP_CONCAT(DISTINCT study_name_short ORDER BY study_name_short SEPARATOR '; ') AS studies

FROM v_literature_variants_flat
GROUP BY
  gene_symbol, lifted_ref_genome, genomic_variant, COALESCE(consequence, 'Unknown');
  
  
