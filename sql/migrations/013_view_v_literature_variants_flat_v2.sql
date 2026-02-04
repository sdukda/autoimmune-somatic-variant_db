USE autoimmune_db;

CREATE OR REPLACE VIEW v_literature_variants_flat AS
SELECT
  ldv.literature_variant_id,
  ldv.study_id,
  s.study_name,
  ldv.study_name_short,
  ldv.gene_symbol,
  ldv.cDNA_HGVS,
  ldv.protein_change,
  ldv.variant_type,
  ldv.is_driver,

  d.disease_id,
  d.disease_name,

  ldv.cell_type_name,
  ct.cell_type_ontology_id,

  ldv.evidence_type,
  ldv.notes,
  ldv.Remarks,

  rgp.ref_genome_name AS paper_ref_genome,
  ldv.paper_chrom,
  ldv.paper_pos,
  ldv.paper_ref,
  ldv.paper_alt,

  rgl.ref_genome_name AS lifted_ref_genome,
  ldv.lifted_chrom,
  ldv.lifted_pos,
  ldv.lifted_ref,
  ldv.lifted_alt

FROM literature_driver_variants ldv
JOIN study s   ON s.study_id = ldv.study_id
JOIN disease d ON d.disease_id = ldv.disease_id
LEFT JOIN cell_type ct ON ct.cell_type_name = ldv.cell_type_name
LEFT JOIN reference_genome rgp ON rgp.ref_genome_id = ldv.paper_ref_genome_id
LEFT JOIN reference_genome rgl ON rgl.ref_genome_id = ldv.lifted_ref_genome_id;
