/* 002_load_literature_driver_variants_from_staging.sql
   Purpose:
   - Load rows from stg_literature_driver_variants into literature_driver_variants
   - Idempotent: uses INSERT IGNORE + uq_ldv_natural_hash on natural_key_sha
   - Maps ref genome names -> reference_genome.ref_genome_id
   - Maps disease_name -> disease.disease_id with a small normalization CASE
*/

INSERT IGNORE INTO literature_driver_variants (
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
  is_driver,
  disease_id,
  cell_type_name,
  evidence_type,
  notes,
  Remarks
)
SELECT
  st.study_id,
  COALESCE(TRIM(st.study_name_short), '')                          AS study_name_short,
  COALESCE(TRIM(st.gene_symbol), '')                               AS gene_symbol,

  NULLIF(TRIM(st.protein_change), '')                              AS protein_change,
  NULLIF(TRIM(st.cDNA_HGVS), '')                                   AS cDNA_HGVS,

  rg_p.ref_genome_id                                               AS paper_ref_genome_id,
  NULLIF(TRIM(st.paper_chrom), '')                                 AS paper_chrom,
  NULLIF(TRIM(st.paper_pos), '')                                   AS paper_pos,
  NULLIF(TRIM(st.paper_ref), '')                                   AS paper_ref,
  NULLIF(TRIM(st.paper_alt), '')                                   AS paper_alt,

  rg_l.ref_genome_id                                               AS lifted_ref_genome_id,
  NULLIF(TRIM(st.lifted_chrom), '')                                AS lifted_chrom,
  NULLIF(TRIM(st.lifted_pos), '')                                  AS lifted_pos,
  NULLIF(TRIM(st.lifted_ref), '')                                  AS lifted_ref,
  NULLIF(TRIM(st.lifted_alt), '')                                  AS lifted_alt,

  COALESCE(TRIM(st.variant_type), '')                              AS variant_type,
  COALESCE(TRIM(st.is_driver), '')                                 AS is_driver,

  d.disease_id                                                     AS disease_id,
  COALESCE(TRIM(st.cell_type_name), '')                            AS cell_type_name,
  COALESCE(TRIM(st.evidence_type), '')                             AS evidence_type,

  st.notes                                                         AS notes,
  COALESCE(st.remarks, '')                                         AS Remarks

FROM stg_literature_driver_variants st

/* Reference genome mapping (paper-reported) */
LEFT JOIN reference_genome rg_p
  ON rg_p.ref_genome_name = TRIM(st.paper_ref_genome_name)

/* Reference genome mapping (lifted-over) */
LEFT JOIN reference_genome rg_l
  ON rg_l.ref_genome_name = TRIM(st.lifted_ref_genome_name)

/* Disease mapping with small normalization */
JOIN disease d
  ON d.disease_name =
     CASE
       WHEN st.disease_name IS NULL OR TRIM(st.disease_name) = '' THEN ''
       WHEN LOWER(TRIM(st.disease_name)) IN ('ibd','inflammatory bowel disease','inflammatory bowel diesease')
         THEN 'Inflammatory bowel disease'
       WHEN LOWER(TRIM(st.disease_name)) IN ('ulcerative colitis','uc')
         THEN 'Ulcerative colitis'
       WHEN LOWER(TRIM(st.disease_name)) IN ('autoimmune lymphoproliferative syndrome (alps)','alps')
         THEN 'Autoimmune lymphoproliferative syndrome'
       WHEN LOWER(TRIM(st.disease_name)) LIKE 'relapsing multiple sclerosis%'
         THEN 'Multiple sclerosis'
       WHEN LOWER(TRIM(st.disease_name)) IN ('chronic liver disease with cirrhosis')
         THEN 'Chronic liver disease'
       ELSE TRIM(st.disease_name)
     END
;
