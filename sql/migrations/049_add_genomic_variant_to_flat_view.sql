CREATE OR REPLACE VIEW v_literature_variants_flat AS
SELECT
  ldv.literature_variant_id,
  ldv.study_id,
  s.study_name,
  ldv.study_name_short,
  ldv.gene_symbol,
  ldv.cDNA_HGVS,
  ldv.protein_change,

  /* ✅ add this */
  CONCAT(
    COALESCE(ldv.lifted_chrom, ldv.paper_chrom), ':',
    COALESCE(ldv.lifted_pos,   ldv.paper_pos),  ' ',
    COALESCE(ldv.lifted_ref,   ldv.paper_ref),  '>',
    COALESCE(ldv.lifted_alt,   ldv.paper_alt)
  ) AS genomic_variant,

  /* Variant type (structural) */
  CASE
    WHEN COALESCE(ldv.lifted_ref, ldv.paper_ref) IS NULL
      OR COALESCE(ldv.lifted_alt, ldv.paper_alt) IS NULL
      THEN NULL
    WHEN CHAR_LENGTH(COALESCE(ldv.lifted_ref, ldv.paper_ref)) = 1
     AND CHAR_LENGTH(COALESCE(ldv.lifted_alt, ldv.paper_alt)) = 1
      THEN 'SNV'
    WHEN CHAR_LENGTH(COALESCE(ldv.lifted_ref, ldv.paper_ref))
       < CHAR_LENGTH(COALESCE(ldv.lifted_alt, ldv.paper_alt))
      THEN 'Insertion'
    WHEN CHAR_LENGTH(COALESCE(ldv.lifted_ref, ldv.paper_ref))
       > CHAR_LENGTH(COALESCE(ldv.lifted_alt, ldv.paper_alt))
      THEN 'Deletion'
    ELSE 'Indel'
  END AS variant_type,

  ldv.variant_impact AS consequence_detail,

  CASE
    WHEN ldv.variant_impact IS NULL THEN 'Unknown'
    WHEN ldv.variant_impact = 'unknown' THEN 'Unknown'
    WHEN ldv.variant_impact LIKE 'frameshift%' THEN 'Frameshift'
    WHEN ldv.variant_impact LIKE 'inframe%' THEN 'Inframe indel'
    WHEN ldv.variant_impact = 'frameshift' THEN 'Frameshift'
    WHEN ldv.variant_impact = 'inframe indel' THEN 'Inframe indel'
    WHEN ldv.variant_impact = 'missense' THEN 'Missense'
    WHEN ldv.variant_impact = 'nonsense' THEN 'Nonsense'
    WHEN ldv.variant_impact = 'splice' THEN 'Splice'
    WHEN ldv.variant_impact = 'synonymous' THEN 'Synonymous'
    WHEN ldv.variant_impact = 'noncoding' THEN 'Noncoding'
    WHEN ldv.variant_impact = 'intron' THEN 'Intron'
    WHEN ldv.variant_impact = 'utr' THEN 'UTR'
    WHEN ldv.variant_impact = 'promoter' THEN 'Promoter'
    WHEN ldv.variant_impact = 'intergenic' THEN 'Intergenic'
    ELSE 'Unknown'
  END AS consequence,

  ldv.is_driver,
  d.disease_id,
  d.disease_name,
  d.category AS disease_category,
  d.disease_ontology_id,
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
JOIN study s ON s.study_id = ldv.study_id
JOIN disease d ON d.disease_id = ldv.disease_id
LEFT JOIN cell_type ct ON ct.cell_type_name = ldv.cell_type_name
LEFT JOIN reference_genome rgp ON rgp.ref_genome_id = ldv.paper_ref_genome_id
LEFT JOIN reference_genome rgl ON rgl.ref_genome_id = ldv.lifted_ref_genome_id;
