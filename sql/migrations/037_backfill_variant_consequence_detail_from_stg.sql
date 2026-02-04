/* Backfill UCSC-derived consequence detail into literature_driver_variants */

UPDATE literature_driver_variants ldv
JOIN stg_ucsc_consequence s
  ON s.genomic_variant = CONCAT(
       COALESCE(ldv.lifted_chrom, ldv.paper_chrom),
       ':',
       COALESCE(ldv.lifted_pos,   ldv.paper_pos),
       ' ',
       COALESCE(ldv.lifted_ref,   ldv.paper_ref),
       '>',
       COALESCE(ldv.lifted_alt,   ldv.paper_alt)
     )
SET
  ldv.variant_consequence_detail = s.variant_consequence_detail
WHERE
  (ldv.variant_consequence_detail IS NULL OR TRIM(ldv.variant_consequence_detail) = '')
  AND s.variant_consequence_detail IS NOT NULL
  AND TRIM(s.variant_consequence_detail) <> '';
