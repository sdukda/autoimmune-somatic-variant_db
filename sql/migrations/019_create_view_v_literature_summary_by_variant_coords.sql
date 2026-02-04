CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER=`root`@`localhost`
SQL SECURITY DEFINER
VIEW v_literature_summary_by_variant_coords AS
SELECT
  ldv.gene_symbol AS gene_symbol,

  /* choose which genome label to display */
  COALESCE(rgl.ref_genome_name, rgp.ref_genome_name) AS ref_genome,

  /* canonical genomic variant string: chr:pos ref>alt (prefer lifted) */
  CONCAT(
    COALESCE(ldv.lifted_chrom, ldv.paper_chrom),
    ':',
    COALESCE(ldv.lifted_pos, ldv.paper_pos),
    ' ',
    COALESCE(ldv.lifted_ref, ldv.paper_ref),
    '>',
    COALESCE(ldv.lifted_alt, ldv.paper_alt)
  ) AS genomic_variant,

  /* B) how many DISTINCT studies reported this exact variant */
  COUNT(DISTINCT ldv.study_id) AS n_studies,

  /* list the studies where reported */
  GROUP_CONCAT(
    DISTINCT COALESCE(ldv.study_name_short, CONCAT('study_id=', ldv.study_id))
    ORDER BY COALESCE(ldv.study_name_short, CONCAT('study_id=', ldv.study_id))
    SEPARATOR '; '
  ) AS studies

FROM literature_driver_variants ldv
LEFT JOIN reference_genome rgp
  ON rgp.ref_genome_id = ldv.paper_ref_genome_id
LEFT JOIN reference_genome rgl
  ON rgl.ref_genome_id = ldv.lifted_ref_genome_id

/* only include rows where we actually have coords */
WHERE
  COALESCE(ldv.lifted_chrom, ldv.paper_chrom) IS NOT NULL
  AND COALESCE(ldv.lifted_pos,   ldv.paper_pos)   IS NOT NULL
  AND COALESCE(ldv.lifted_ref,   ldv.paper_ref)   IS NOT NULL
  AND COALESCE(ldv.lifted_alt,   ldv.paper_alt)   IS NOT NULL
  AND COALESCE(ldv.lifted_chrom, ldv.paper_chrom) <> ''
  AND COALESCE(ldv.lifted_ref,   ldv.paper_ref)   <> ''
  AND COALESCE(ldv.lifted_alt,   ldv.paper_alt)   <> ''

GROUP BY
  ldv.gene_symbol,
  ref_genome,
  genomic_variant;
