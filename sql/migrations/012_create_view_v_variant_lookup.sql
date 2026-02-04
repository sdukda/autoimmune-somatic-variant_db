-- 012_create_view_v_variant_lookup.sql
-- Purpose:
--   A single “lookup” view a researcher can query by:
--     - gene (gene_symbol)
--     - disease (disease_name)
--     - study (study_name)
--     - coordinates (paper_* or lifted_*)
--   This avoids needing to know literature_variant_id.

DROP VIEW IF EXISTS v_variant_lookup;

CREATE VIEW v_variant_lookup AS
SELECT
  ldv.literature_variant_id,
  ldv.study_id,
  s.study_name,

  ldv.gene_symbol,
  ldv.cDNA_HGVS,
  ldv.protein_change,
  ldv.variant_type,
  ldv.is_driver,

  d.disease_id,
  d.disease_name,

  ldv.cell_type_name,
  ldv.evidence_type,

  -- paper coords
  rgp.ref_genome_name AS paper_ref_genome_name,
  ldv.paper_chrom,
  ldv.paper_pos,
  ldv.paper_ref,
  ldv.paper_alt,

  -- lifted coords
  rgl.ref_genome_name AS lifted_ref_genome_name,
  ldv.lifted_chrom,
  ldv.lifted_pos,
  ldv.lifted_ref,
  ldv.lifted_alt,

  ldv.notes,
  ldv.Remarks

FROM literature_driver_variants ldv
JOIN study s
  ON s.study_id = ldv.study_id
JOIN disease d
  ON d.disease_id = ldv.disease_id
LEFT JOIN reference_genome rgp
  ON rgp.ref_genome_id = ldv.paper_ref_genome_id
LEFT JOIN reference_genome rgl
  ON rgl.ref_genome_id = ldv.lifted_ref_genome_id;

