-- 039_make_consequence_enum.sql
USE autoimmune_db;

-- --------------------------------------------------
-- 0) Drop legacy CHECK that blocks ENUM conversion
-- --------------------------------------------------
ALTER TABLE literature_driver_variants
DROP CHECK chk_ldv_variant_impact_atomic;
-- --------------------------------------------------

-- 1) Backfill variant_impact using UCSC curation
--    (only where variant_impact is missing)
-- --------------------------------------------------
UPDATE literature_driver_variants ldv
JOIN stg_ucsc_consequence s
  ON s.literature_variant_id = ldv.literature_variant_id
SET ldv.variant_impact = LOWER(TRIM(s.variant_consequence_detail))
WHERE ldv.variant_impact IS NULL
   OR TRIM(ldv.variant_impact) = '';

-- --------------------------------------------------
-- 2) Normalize legacy values (case + wording)
-- --------------------------------------------------
UPDATE literature_driver_variants SET variant_impact='missense'   WHERE variant_impact='Missense';
UPDATE literature_driver_variants SET variant_impact='nonsense'   WHERE variant_impact='Nonsense';
UPDATE literature_driver_variants SET variant_impact='splice'     WHERE variant_impact='Splice';
UPDATE literature_driver_variants SET variant_impact='synonymous' WHERE variant_impact='Synonymous';
UPDATE literature_driver_variants SET variant_impact='noncoding'  WHERE variant_impact='Noncoding';

-- --------------------------------------------------
-- 3) Sanity check BEFORE ENUM conversion
-- --------------------------------------------------
SELECT variant_impact, COUNT(*) n
FROM literature_driver_variants
GROUP BY variant_impact
ORDER BY n DESC;

-- --------------------------------------------------
-- 4) Convert consequence column to ENUM
-- --------------------------------------------------
ALTER TABLE literature_driver_variants
MODIFY variant_impact ENUM(
  'missense',
  'nonsense',
  'splice',
  'synonymous',
  'noncoding',

  -- allow bucket-only values (needed for your existing data)
  'frameshift',
  'inframe indel',

  -- allow the detailed dropdown values
  'frameshift insertion',
  'frameshift deletion',
  'frameshift delins',
  'inframe insertion',
  'inframe deletion',
  'inframe delins'
) DEFAULT NULL;

-- --------------------------------------------------
-- 5) Drop obsolete column (supervisor instruction)
-- --------------------------------------------------
ALTER TABLE literature_driver_variants
DROP COLUMN variant_consequence_detail;

-- --------------------------------------------------
-- 6) Recreate flat view with:
--    - consequence_detail = ENUM value
--    - consequence        = derived bucket
-- --------------------------------------------------
CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER=`root`@`localhost`
SQL SECURITY DEFINER
VIEW v_literature_variants_flat AS
SELECT
  ldv.literature_variant_id,
  ldv.study_id,
  s.study_name,
  ldv.study_name_short,
  ldv.gene_symbol,
  ldv.cDNA_HGVS,
  ldv.protein_change,

  -- Variant type (structural)
  (CASE
    WHEN COALESCE(ldv.lifted_ref, ldv.paper_ref) IS NULL
      OR COALESCE(ldv.lifted_alt, ldv.paper_alt) IS NULL
      THEN NULL
    WHEN CHAR_LENGTH(COALESCE(ldv.lifted_ref, ldv.paper_ref)) = 1
     AND CHAR_LENGTH(COALESCE(ldv.lifted_alt, ldv.paper_alt)) = 1 THEN 'SNV'
    WHEN CHAR_LENGTH(COALESCE(ldv.lifted_ref, ldv.paper_ref)) <
         CHAR_LENGTH(COALESCE(ldv.lifted_alt, ldv.paper_alt)) THEN 'Insertion'
    WHEN CHAR_LENGTH(COALESCE(ldv.lifted_ref, ldv.paper_ref)) >
         CHAR_LENGTH(COALESCE(ldv.lifted_alt, ldv.paper_alt)) THEN 'Deletion'
    ELSE 'Indel'
  END) AS variant_type,

  -- Detailed ENUM (stored)
  ldv.variant_impact AS consequence_detail,

  -- Bucket (derived for UI)
  (CASE
     WHEN ldv.variant_impact LIKE 'frameshift %' THEN 'Frameshift'
     WHEN ldv.variant_impact LIKE 'inframe %'    THEN 'Inframe indel'
     WHEN ldv.variant_impact = 'missense'        THEN 'Missense'
     WHEN ldv.variant_impact = 'nonsense'        THEN 'Nonsense'
     WHEN ldv.variant_impact = 'splice'          THEN 'Splice'
     WHEN ldv.variant_impact = 'synonymous'      THEN 'Synonymous'
     WHEN ldv.variant_impact = 'noncoding'       THEN 'Noncoding'
     ELSE NULL
  END) AS consequence,

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
