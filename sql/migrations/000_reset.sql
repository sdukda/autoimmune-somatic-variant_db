-- 000_reset.sql — drop all tables so you can rerun migrations cleanly
USE autoimmune_db;

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS
  annotation_prediction,
  external_annotation,
  gene_overlap,
  study_variant,
  study_ref_paper,
  evidence,
  variant_annotation,
  cell,
  sample,
  variants,
  transcripts,
  genes,
  disease,
  ref_paper,         -- canonical name
  reference_paper,   -- stray earlier name (drop if present)
  study,
  technology,
  variant_impact,
  impact_severity,
  variant_type,
  reference_genome;

SET FOREIGN_KEY_CHECKS = 1;
