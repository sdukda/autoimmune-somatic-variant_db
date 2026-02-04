-- 045_extend_summary_view_with_consequence.sql
USE autoimmune_db;

CREATE OR REPLACE VIEW v_literature_summary_by_variant_coords AS
SELECT
  gene_symbol,
  COALESCE(lifted_ref_genome, paper_ref_genome) AS ref_genome,
  genomic_variant,
  COUNT(*) AS n_reports,
  COUNT(DISTINCT study_id) AS n_studies,
  GROUP_CONCAT(DISTINCT study_name_short
               ORDER BY study_name_short
               SEPARATOR '; ') AS studies,
  MAX(consequence) AS consequence
FROM (
  SELECT
    v.gene_symbol,
    v.paper_ref_genome,
    v.lifted_ref_genome,
    CONCAT(
      COALESCE(v.lifted_chrom, v.paper_chrom), ':',
      COALESCE(v.lifted_pos,   v.paper_pos),  ' ',
      COALESCE(v.lifted_ref,   v.paper_ref),  '>',
      COALESCE(v.lifted_alt,   v.paper_alt)
    ) AS genomic_variant,
    v.study_id,
    v.study_name_short,
    v.consequence
  FROM v_literature_variants_flat v
) x
GROUP BY gene_symbol, ref_genome, genomic_variant;
