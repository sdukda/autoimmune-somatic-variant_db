USE autoimmune_db;

INSERT INTO literature_driver_variants (
  study_id,
  study_name_short,
  gene_symbol,
  protein_change,
  cDNA_HGVS,

  paper_ref_genome_id,
  paper_chrom,
  paper_pos,
  paper_ref,
  paper_alt,

  lifted_ref_genome_id,
  lifted_chrom,
  lifted_pos,
  lifted_ref,
  lifted_alt,

  variant_type,
  variant_type_norm,
  variant_impact,

  is_driver,
  disease_id,
  cell_type_name,
  evidence_type,
  notes,
  Remarks
)
SELECT
  s.study_id,
  s.study_name_short,
  TRIM(s.gene_symbol)                                      AS gene_symbol,
  NULLIF(TRIM(s.protein_change), '')                       AS protein_change,
  NULLIF(TRIM(s.cDNA_HGVS), '')                            AS cDNA_HGVS,

  rgp.ref_genome_id                                        AS paper_ref_genome_id,
  NULLIF(TRIM(s.paper_chrom), '')                          AS paper_chrom,
  NULLIF(TRIM(s.paper_pos), '')                            AS paper_pos,
  NULLIF(TRIM(s.paper_ref), '')                            AS paper_ref,
  NULLIF(TRIM(s.paper_alt), '')                            AS paper_alt,

  rgl.ref_genome_id                                        AS lifted_ref_genome_id,
  NULLIF(TRIM(s.lifted_chrom), '')                         AS lifted_chrom,
  NULLIF(TRIM(s.lifted_pos), '')                           AS lifted_pos,
  NULLIF(TRIM(s.lifted_ref), '')                           AS lifted_ref,
  NULLIF(TRIM(s.lifted_alt), '')                           AS lifted_alt,

  /* Atomic variant_type required by chk_ldv_variant_type_atomic */
  CASE
    WHEN s.variant_type IS NULL OR TRIM(s.variant_type) = '' THEN NULL
    WHEN LOWER(TRIM(s.variant_type)) LIKE '%mnv%' THEN 'MNV'
    WHEN LOWER(TRIM(s.variant_type)) LIKE '%snv%' THEN 'SNV'
    WHEN LOWER(TRIM(s.variant_type)) LIKE '%insertion%' OR LOWER(TRIM(s.variant_type)) LIKE '%ins%' THEN 'Insertion'
    WHEN LOWER(TRIM(s.variant_type)) LIKE '%deletion%'  OR LOWER(TRIM(s.variant_type)) LIKE '%del%' THEN 'Deletion'
    WHEN LOWER(TRIM(s.variant_type)) LIKE '%indel%' THEN 'Indel'
    /* If your staging sometimes has already-clean atomic values */
    WHEN TRIM(s.variant_type) IN ('SNV','Insertion','Deletion','Indel','MNV') THEN TRIM(s.variant_type)
    ELSE NULL
  END                                                     AS variant_type,

  /* Keep norm consistent (or NULL) */
  CASE
    WHEN s.variant_type IS NULL OR TRIM(s.variant_type) = '' THEN NULL
    WHEN LOWER(TRIM(s.variant_type)) LIKE '%mnv%' THEN 'MNV'
    WHEN LOWER(TRIM(s.variant_type)) LIKE '%snv%' THEN 'SNV'
    WHEN LOWER(TRIM(s.variant_type)) LIKE '%insertion%' OR LOWER(TRIM(s.variant_type)) LIKE '%ins%' THEN 'Insertion'
    WHEN LOWER(TRIM(s.variant_type)) LIKE '%deletion%'  OR LOWER(TRIM(s.variant_type)) LIKE '%del%' THEN 'Deletion'
    WHEN LOWER(TRIM(s.variant_type)) LIKE '%indel%' THEN 'Indel'
    WHEN TRIM(s.variant_type) IN ('SNV','Insertion','Deletion','Indel','MNV') THEN TRIM(s.variant_type)
    ELSE NULL
  END                                                     AS variant_type_norm,

  /* Your staging has no variant_impact column; keep NULL for now */
  NULL                                                    AS variant_impact,

  TRIM(s.is_driver)                                       AS is_driver,

  COALESCE(m.disease_id, d.disease_id)                    AS disease_id,

  TRIM(s.cell_type_name)                                  AS cell_type_name,
  TRIM(s.evidence_type)                                   AS evidence_type,
  NULLIF(TRIM(s.notes), '')                               AS notes,

  /* Remarks is NOT NULL in table */
  COALESCE(NULLIF(TRIM(s.remarks), ''), '')               AS Remarks

FROM stg_literature_driver_variants s

LEFT JOIN stg_disease_name_map m
  ON LOWER(TRIM(m.stg_disease_name)) = LOWER(TRIM(s.disease_name))

LEFT JOIN disease d
  ON LOWER(TRIM(d.disease_name)) = LOWER(TRIM(s.disease_name))

LEFT JOIN reference_genome rgp
  ON rgp.ref_genome_name = s.paper_ref_genome_name

LEFT JOIN reference_genome rgl
  ON rgl.ref_genome_name = s.lifted_ref_genome_name

WHERE
  s.study_id IS NOT NULL
  AND NULLIF(TRIM(s.study_name_short), '') IS NOT NULL
  AND NULLIF(TRIM(s.gene_symbol), '') IS NOT NULL
  AND NULLIF(TRIM(s.is_driver), '') IS NOT NULL
  AND NULLIF(TRIM(s.cell_type_name), '') IS NOT NULL
  AND NULLIF(TRIM(s.evidence_type), '') IS NOT NULL
  AND COALESCE(m.disease_id, d.disease_id) IS NOT NULL

ON DUPLICATE KEY UPDATE
  evidence_type = VALUES(evidence_type),
  notes         = VALUES(notes),
  Remarks       = VALUES(Remarks);
