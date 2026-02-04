CREATE TABLE IF NOT EXISTS stg_ucsc_consequence (
  literature_variant_id BIGINT NULL,
  genomic_variant VARCHAR(255) NOT NULL,
  variant_consequence_detail VARCHAR(128) NOT NULL,

  PRIMARY KEY (genomic_variant),
  KEY idx_lvid (literature_variant_id)
);
