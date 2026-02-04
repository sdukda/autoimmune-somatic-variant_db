-- 038_reload_stg_ucsc_consequence.sql

TRUNCATE TABLE stg_ucsc_consequence;

LOAD DATA LOCAL INFILE '../seeds/literature_variant_consequence_ucsc_v1.csv'
INTO TABLE stg_ucsc_consequence
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@gene_symbol, @genomic_variant, @detail)
SET
  genomic_variant = REPLACE(TRIM(@genomic_variant), ' >', '>'),
  variant_consequence_detail = TRIM(@detail);
