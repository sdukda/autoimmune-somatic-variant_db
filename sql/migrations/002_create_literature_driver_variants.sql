CREATE TABLE IF NOT EXISTS literature_driver_variants (
  literature_variant_id BIGINT NOT NULL AUTO_INCREMENT,

  -- Study / paper
  study_id BIGINT NOT NULL,
  study_name_short VARCHAR(255) NOT NULL,

  -- Variant identity
  gene_symbol VARCHAR(32) NOT NULL,
  protein_change VARCHAR(128) DEFAULT NULL,
  cDNA_HGVS VARCHAR(128) DEFAULT NULL,

  -- Paper-reported reference genome (lookup)
  paper_ref_genome_id BIGINT DEFAULT NULL,

  -- Paper-reported genomic coordinates (ONLY if stated in paper)
  paper_chrom VARCHAR(16) DEFAULT NULL,
  paper_pos VARCHAR(64) DEFAULT NULL,
  paper_ref VARCHAR(255) DEFAULT NULL,
  paper_alt VARCHAR(255) DEFAULT NULL,

  -- Variant classification
  variant_type VARCHAR(128) NOT NULL,
  is_driver VARCHAR(128) NOT NULL,

  -- Disease & cell context (lookups)
  disease_id BIGINT NOT NULL,
  cell_type_name VARCHAR(255) NOT NULL,

  -- Evidence
  evidence_type VARCHAR(128) NOT NULL,

  -- Curation notes (important)
  notes TEXT DEFAULT NULL,

  -- Citation (ALWAYS filled)
  Remarks TEXT NOT NULL,

  PRIMARY KEY (literature_variant_id),

  -- Foreign keys
  CONSTRAINT fk_ldv_study
    FOREIGN KEY (study_id)
    REFERENCES study(study_id),

  CONSTRAINT fk_ldv_ref_genome
    FOREIGN KEY (paper_ref_genome_id)
    REFERENCES reference_genome(ref_genome_id),

  CONSTRAINT fk_ldv_disease
    FOREIGN KEY (disease_id)
    REFERENCES disease(disease_id),

  -- Helpful indexes
  KEY idx_ldv_gene (gene_symbol),
  KEY idx_ldv_disease (disease_id),
  KEY idx_ldv_study (study_id)

) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_unicode_ci;
