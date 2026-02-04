USE autoimmune_db;

DROP VIEW IF EXISTS v_literature_variants_flat;

CREATE VIEW v_literature_variants_flat AS
SELECT
  ldv.literature_variant_id,
  ldv.study_id,
  s.study_name,
  ldv.study_name_short,

  ldv.gene_symbol,
  ldv.cDNA_HGVS,
  ldv.protein_change,

  ldv.variant_type,

  -- keep the detailed stored value available (optional but fine)
  ldv.variant_impact,

  CASE
    WHEN ldv.variant_impact = 'frameshift'            THEN 'Frameshift'
    WHEN ldv.variant_impact = 'frameshift insertion'  THEN 'Frameshift'
    WHEN ldv.variant_impact = 'frameshift deletion'   THEN 'Frameshift'
    WHEN ldv.variant_impact = 'frameshift delins'     THEN 'Frameshift'

    WHEN ldv.variant_impact = 'missense'              THEN 'Missense'
    WHEN ldv.variant_impact = 'nonsense'              THEN 'Nonsense'
    WHEN ldv.variant_impact = 'splice'                THEN 'Splice'

    WHEN ldv.variant_impact = 'inframe indel'         THEN 'Inframe indel'
    WHEN ldv.variant_impact = 'inframe insertion'     THEN 'Inframe indel'
    WHEN ldv.variant_impact = 'inframe deletion'      THEN 'Inframe indel'
    WHEN ldv.variant_impact = 'inframe delins'        THEN 'Inframe indel'

    -- ✅ NONCODING EXTENSION
    WHEN ldv.variant_impact = 'intron'                THEN 'Intron'
    WHEN ldv.variant_impact = 'utr'                   THEN 'UTR'
    WHEN ldv.variant_impact = 'promoter'              THEN 'Promoter'
    WHEN ldv.variant_impact = 'intergenic'            THEN 'Intergenic'
    WHEN ldv.variant_impact = 'noncoding'             THEN 'Noncoding'

    ELSE NULL
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
