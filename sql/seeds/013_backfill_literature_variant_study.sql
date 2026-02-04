-- 013_backfill_literature_variant_study.sql
-- Correct backfill: matches literature_driver_variants.natural_key_sha which uses disease_id (not disease_name).

-- 1) Ensure idempotency for links
ALTER TABLE literature_variant_study
  ADD UNIQUE KEY uq_lvs_variant_study (literature_variant_id, study_id);

-- 2) Insert links from staging -> evidence table
INSERT IGNORE INTO literature_variant_study (
  literature_variant_id,
  study_id,
  evidence_type,
  notes
)
SELECT
  ldv.literature_variant_id,
  st.study_id,
  NULLIF(TRIM(st.evidence_type), '') AS evidence_type,
  CONCAT('Backfilled from staging. study_name_short=', COALESCE(NULLIF(TRIM(st.study_name_short), ''), '[NULL]')) AS notes
FROM stg_literature_driver_variants st
JOIN disease d
  ON d.disease_name = CASE
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
JOIN literature_driver_variants ldv
  ON ldv.natural_key_sha = UNHEX(
    SHA2(
      CONCAT_WS('|',
        st.study_id,
        COALESCE(NULLIF(TRIM(st.gene_symbol), ''), ''),
        COALESCE(NULLIF(TRIM(st.cDNA_HGVS), ''), ''),
        COALESCE(NULLIF(TRIM(st.protein_change), ''), ''),
        COALESCE(NULLIF(TRIM(st.paper_chrom), ''), ''),
        COALESCE(NULLIF(TRIM(st.paper_pos), ''), ''),
        COALESCE(NULLIF(TRIM(st.paper_ref), ''), ''),
        COALESCE(NULLIF(TRIM(st.paper_alt), ''), ''),
        d.disease_id,
        COALESCE(NULLIF(TRIM(st.cell_type_name), ''), '')
      ),
      256
    )
  );
