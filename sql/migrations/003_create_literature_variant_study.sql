CREATE TABLE literature_variant_study (
  literature_variant_study_id BIGINT AUTO_INCREMENT PRIMARY KEY,

  literature_variant_id BIGINT NOT NULL,
  study_id              BIGINT NOT NULL,

  evidence_type VARCHAR(128),
  notes         TEXT,

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_lvs_variant
    FOREIGN KEY (literature_variant_id)
    REFERENCES literature_driver_variants (literature_variant_id),

  CONSTRAINT fk_lvs_study
    FOREIGN KEY (study_id)
    REFERENCES study (study_id),

  CONSTRAINT uq_lvs_variant_study
    UNIQUE (literature_variant_id, study_id)
) ENGINE=InnoDB;
