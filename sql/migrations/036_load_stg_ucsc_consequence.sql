TRUNCATE TABLE stg_ucsc_consequence;

LOAD DATA LOCAL INFILE '../seeds/literature_variant_consequence_ucsc_v1.csv'
INTO TABLE stg_ucsc_consequence
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
  @literature_variant_id,
  @genomic_variant,
  @variant_consequence_detail
)
SET
  literature_variant_id = NULLIF(TRIM(@literature_variant_id), ''),
  genomic_variant = TRIM(@genomic_variant),
  variant_consequence_detail = TRIM(@variant_consequence_detail);
