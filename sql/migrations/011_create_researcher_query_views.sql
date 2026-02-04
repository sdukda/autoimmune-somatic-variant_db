-- 011_create_researcher_query_views.sql
-- Purpose:
--   Researcher-facing views that make it easy to query variants by:
--   gene, disease, study, and evidence trail (study links).
--
-- Notes:
--   These are "read views" only (no table changes).
--   Safe to re-run because we use CREATE OR REPLACE VIEW.


-- 1) Flat view for UI + general querying (one row per variant)

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
  ldv.evidence_type,
  ldv.notes,
  ldv.Remarks,

  -- Paper coordinates (as stored)
  rgp.ref_genome_name AS paper_ref_genome,
  ldv.paper_chrom,
  ldv.paper_pos,
  ldv.paper_ref,
  ldv.paper_alt,

  -- Lifted coordinates (as stored)
  rgl.ref_genome_name AS lifted_ref_genome,
  ldv.lifted_chrom,
  ldv.lifted_pos,
  ldv.lifted_ref,
  ldv.lifted_alt

FROM literature_driver_variants ldv
JOIN study s
  ON s.study_id = ldv.study_id
JOIN disease d
  ON d.disease_id = ldv.disease_id
LEFT JOIN reference_genome rgp
  ON rgp.ref_genome_id = ldv.paper_ref_genome_id
LEFT JOIN reference_genome rgl
  ON rgl.ref_genome_id = ldv.lifted_ref_genome_id;


-- 2) Evidence trail view (variant ↔ study link table)
--    This is what researchers want for provenance.

CREATE OR REPLACE VIEW v_literature_variant_evidence AS
SELECT
  lvs.literature_variant_study_id,
  lvs.literature_variant_id,
  lvs.study_id,
  s.study_name,
  lvs.evidence_type AS link_evidence_type,
  lvs.notes AS link_notes,
  lvs.created_at
FROM literature_variant_study lvs
JOIN study s
  ON s.study_id = lvs.study_id;


-- 3) Variant + evidence in one place (flat + provenance)
--    Useful for UI drill-down pages: variant → evidence links.

CREATE OR REPLACE VIEW v_literature_variants_with_evidence AS
SELECT
  vf.*,
  lvs.literature_variant_study_id,
  lvs.created_at AS evidence_link_created_at,
  lvs.evidence_type AS evidence_link_type,
  lvs.notes AS evidence_link_notes
FROM v_literature_variants_flat vf
LEFT JOIN literature_variant_study lvs
  ON lvs.literature_variant_id = vf.literature_variant_id
  AND lvs.study_id = vf.study_id;


-- 4) Gene recurrence across studies
--    "Which genes recur across multiple studies?"
CREATE OR REPLACE VIEW v_gene_recurrence_across_studies AS
SELECT
  ldv.gene_symbol,
  COUNT(DISTINCT ldv.study_id) AS n_studies,
  COUNT(DISTINCT ldv.disease_id) AS n_diseases,
  COUNT(*) AS n_variants
FROM literature_driver_variants ldv
GROUP BY ldv.gene_symbol;


-- 5) Gene × disease summary
--    "For disease X, which genes and how many variants?"

CREATE OR REPLACE VIEW v_gene_by_disease_summary AS
SELECT
  d.disease_id,
  d.disease_name,
  ldv.gene_symbol,
  COUNT(DISTINCT ldv.study_id) AS n_studies,
  COUNT(*) AS n_variants
FROM literature_driver_variants ldv
JOIN disease d
  ON d.disease_id = ldv.disease_id
GROUP BY d.disease_id, d.disease_name, ldv.gene_symbol;


-- 6) Disease recurrence across studies
--    (useful when you add more diseases later)

CREATE OR REPLACE VIEW v_disease_recurrence_across_studies AS
SELECT
  d.disease_id,
  d.disease_name,
  COUNT(DISTINCT ldv.study_id) AS n_studies,
  COUNT(*) AS n_variants,
  COUNT(DISTINCT ldv.gene_symbol) AS n_genes
FROM literature_driver_variants ldv
JOIN disease d
  ON d.disease_id = ldv.disease_id
GROUP BY d.disease_id, d.disease_name;


-- 7) Coordinate completeness checks (paper coords)
--    "Which rows are missing paper coordinate details?"

CREATE OR REPLACE VIEW v_literature_variants_missing_paper_coords AS
SELECT
  ldv.literature_variant_id,
  ldv.study_id,
  s.study_name,
  ldv.gene_symbol,
  ldv.cDNA_HGVS,
  ldv.protein_change,
  d.disease_name,
  ldv.paper_ref_genome_id,
  ldv.paper_chrom,
  ldv.paper_pos,
  ldv.paper_ref,
  ldv.paper_alt,
  ldv.Remarks
FROM literature_driver_variants ldv
JOIN study s ON s.study_id = ldv.study_id
JOIN disease d ON d.disease_id = ldv.disease_id
WHERE
  ldv.paper_chrom IS NULL OR TRIM(ldv.paper_chrom) = ''
  OR ldv.paper_pos IS NULL OR TRIM(ldv.paper_pos) = ''
  OR ldv.paper_ref IS NULL OR TRIM(ldv.paper_ref) = ''
  OR ldv.paper_alt IS NULL OR TRIM(ldv.paper_alt) = '';


-- 8) Coordinate completeness checks (lifted coords)
--    "Which rows are missing lifted coordinates?"

CREATE OR REPLACE VIEW v_literature_variants_missing_lifted_coords AS
SELECT
  ldv.literature_variant_id,
  ldv.study_id,
  s.study_name,
  ldv.gene_symbol,
  ldv.cDNA_HGVS,
  ldv.protein_change,
  d.disease_name,
  ldv.lifted_ref_genome_id,
  ldv.lifted_chrom,
  ldv.lifted_pos,
  ldv.lifted_ref,
  ldv.lifted_alt,
  ldv.Remarks
FROM literature_driver_variants ldv
JOIN study s ON s.study_id = ldv.study_id
JOIN disease d ON d.disease_id = ldv.disease_id
WHERE
  ldv.lifted_chrom IS NULL OR TRIM(ldv.lifted_chrom) = ''
  OR ldv.lifted_pos IS NULL OR TRIM(ldv.lifted_pos) = ''
  OR ldv.lifted_ref IS NULL OR TRIM(ldv.lifted_ref) = ''
  OR ldv.lifted_alt IS NULL OR TRIM(ldv.lifted_alt) = '';
