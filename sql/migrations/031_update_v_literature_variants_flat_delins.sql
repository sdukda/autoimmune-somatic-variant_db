-- 031_update_v_literature_variants_flat_delins.sql
-- Ensure delins consequence categories appear correctly in v_literature_variants_flat

CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER=`root`@`localhost`
SQL SECURITY DEFINER
VIEW `v_literature_variants_flat` AS
SELECT
  ldv.literature_variant_id                                   AS literature_variant_id,
  ldv.study_id                                                AS study_id,
  s.study_name                                                AS study_name,
  ldv.study_name_short                                        AS study_name_short,

  ldv.gene_symbol                                             AS gene_symbol,
  ldv.cDNA_HGVS                                               AS cDNA_HGVS,
  ldv.protein_change                                          AS protein_change,

  /* variant_type (mutation class): SNV / Insertion / Deletion / Indel / MNV */
  CASE
    WHEN COALESCE(ldv.lifted_ref, ldv.paper_ref) IS NULL
      OR COALESCE(ldv.lifted_alt, ldv.paper_alt) IS NULL
      OR COALESCE(ldv.lifted_ref, ldv.paper_ref) = ''
      OR COALESCE(ldv.lifted_alt, ldv.paper_alt) = ''
      THEN NULL
    WHEN COALESCE(ldv.lifted_ref, ldv.paper_ref) = '-' AND COALESCE(ldv.lifted_alt, ldv.paper_alt) <> '-' THEN 'Insertion'
    WHEN COALESCE(ldv.lifted_alt, ldv.paper_alt) = '-' AND COALESCE(ldv.lifted_ref, ldv.paper_ref) <> '-' THEN 'Deletion'
    WHEN CHAR_LENGTH(COALESCE(ldv.lifted_ref, ldv.paper_ref)) = 1
     AND CHAR_LENGTH(COALESCE(ldv.lifted_alt, ldv.paper_alt)) = 1 THEN 'SNV'
    WHEN CHAR_LENGTH(COALESCE(ldv.lifted_ref, ldv.paper_ref)) < CHAR_LENGTH(COALESCE(ldv.lifted_alt, ldv.paper_alt)) THEN 'Insertion'
    WHEN CHAR_LENGTH(COALESCE(ldv.lifted_ref, ldv.paper_ref)) > CHAR_LENGTH(COALESCE(ldv.lifted_alt, ldv.paper_alt)) THEN 'Deletion'
    WHEN CHAR_LENGTH(COALESCE(ldv.lifted_ref, ldv.paper_ref)) > 1
     AND CHAR_LENGTH(COALESCE(ldv.lifted_alt, ldv.paper_alt)) > 1 THEN 'MNV'
    ELSE 'Indel'
  END                                                        AS variant_type,

  /* consequence (from variant_impact) – preserve delins */
  CASE
    WHEN ldv.variant_impact IS NULL OR TRIM(ldv.variant_impact) = '' THEN NULL

    /* preserve explicit delins buckets FIRST */
    WHEN LOWER(ldv.variant_impact) LIKE '%frameshift%delins%' THEN 'Frameshift delins'
    WHEN LOWER(ldv.variant_impact) LIKE '%inframe%delins%'    THEN 'Inframe delins'

    /* then the usual buckets */
    WHEN LOWER(ldv.variant_impact) LIKE '%nonsense%'
      OR LOWER(ldv.variant_impact) LIKE '%stop-gain%'
      OR LOWER(ldv.variant_impact) LIKE '%stopgain%'
      OR LOWER(ldv.variant_impact) LIKE '%stop%' THEN 'Nonsense'

    WHEN LOWER(ldv.variant_impact) LIKE '%frameshift%' THEN 'Frameshift'
    WHEN LOWER(ldv.variant_impact) LIKE '%missense%'   THEN 'Missense'
    WHEN LOWER(ldv.variant_impact) LIKE '%splice%'     THEN 'Splice'
    WHEN LOWER(ldv.variant_impact) LIKE '%synonymous%' THEN 'Synonymous'
    WHEN LOWER(ldv.variant_impact) LIKE '%noncoding%'  THEN 'Noncoding'
    WHEN LOWER(ldv.variant_impact) LIKE '%inframe%'    THEN 'Inframe indel'

    ELSE TRIM(REGEXP_REPLACE(ldv.variant_impact, '\\s*\\(.*\\)\\s*', ''))
  END                                                        AS consequence,

  ldv.is_driver                                              AS is_driver,

  d.disease_id                                               AS disease_id,
  d.disease_name                                             AS disease_name,
  d.category                                                 AS disease_category,
  d.disease_ontology_id                                      AS disease_ontology_id,

  ldv.cell_type_name                                         AS cell_type_name,
  ct.cell_type_ontology_id                                   AS cell_type_ontology_id,

  ldv.evidence_type                                          AS evidence_type,
  ldv.notes                                                  AS notes,
  ldv.Remarks                                                AS Remarks,

  rgp.ref_genome_name                                        AS paper_ref_genome,
  ldv.paper_chrom                                            AS paper_chrom,
  ldv.paper_pos                                              AS paper_pos,
  ldv.paper_ref                                              AS paper_ref,
  ldv.paper_alt                                              AS paper_alt,

  rgl.ref_genome_name                                        AS lifted_ref_genome,
  ldv.lifted_chrom                                           AS lifted_chrom,
  ldv.lifted_pos                                             AS lifted_pos,
  ldv.lifted_ref                                             AS lifted_ref,
  ldv.lifted_alt                                             AS lifted_alt

FROM literature_driver_variants ldv
JOIN study s
  ON s.study_id = ldv.study_id
JOIN disease d
  ON d.disease_id = ldv.disease_id
LEFT JOIN cell_type ct
  ON ct.cell_type_name = ldv.cell_type_name
LEFT JOIN reference_genome rgp
  ON rgp.ref_genome_id = ldv.paper_ref_genome_id
LEFT JOIN reference_genome rgl
  ON rgl.ref_genome_id = ldv.lifted_ref_genome_id;
