DROP VIEW IF EXISTS v_literature_summary_by_variant_coords;

CREATE VIEW v_literature_summary_by_variant_coords AS
SELECT
  gene_symbol,
  paper_ref_genome AS ref_genome,
  genomic_variant,
  COALESCE(consequence, 'Unknown') AS consequence,
  COUNT(*) AS n_reports,
  COUNT(DISTINCT study_id) AS n_studies,
  GROUP_CONCAT(DISTINCT study_name_short ORDER BY study_name_short SEPARATOR '; ') AS studies,

  /* NEW */
  GROUP_CONCAT(DISTINCT protein_change ORDER BY protein_change SEPARATOR '; ') AS protein_change

FROM v_literature_variants_flat
GROUP BY
  gene_symbol,
  paper_ref_genome,
  genomic_variant,
  COALESCE(consequence, 'Unknown');
