/* 034_backfill_variant_consequence_detail.sql
   Backfill UCSC-derived consequence details for formerly no-SNV variants
*/

DROP TEMPORARY TABLE IF EXISTS tmp_ucsc_consequence;

CREATE TEMPORARY TABLE tmp_ucsc_consequence (
  ref_genome                 VARCHAR(32),
  genomic_variant            VARCHAR(255),
  variant_consequence_detail VARCHAR(128),
  curation_source            VARCHAR(64)
);

-- Load YOUR CSV (exact filename)
LOAD DATA LOCAL INFILE '../seeds/literature_variant_consequence_ucsc_v1.csv'
INTO TABLE tmp_ucsc_consequence
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(ref_genome, genomic_variant, variant_consequence_detail, curation_source);

-- Backfill into main table
UPDATE literature_driver_variants ldv
JOIN tmp_ucsc_consequence u
  ON u.genomic_variant = CONCAT(
      COALESCE(ldv.lifted_chrom, ldv.paper_chrom),
      ':',
      COALESCE(ldv.lifted_pos, ldv.paper_pos),
      ' ',
      COALESCE(ldv.lifted_ref, ldv.paper_ref),
      '>',
      COALESCE(ldv.lifted_alt, ldv.paper_alt)
  )
SET
  ldv.variant_consequence_detail = u.variant_consequence_detail
WHERE
  ldv.variant_consequence_detail IS NULL
  OR TRIM(ldv.variant_consequence_detail) = '';

-- Sanity checks
SELECT COUNT(*) AS n_ucsc_rows FROM tmp_ucsc_consequence;

SELECT
  variant_consequence_detail,
  COUNT(*) AS n
FROM literature_driver_variants
GROUP BY variant_consequence_detail
ORDER BY n DESC;
