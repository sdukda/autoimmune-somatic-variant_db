-- sql/migrations/006_create_sample_annotation.sql
USE autoimmune_db;

CREATE TABLE IF NOT EXISTS sample_annotation (
  sample_annotation_id BIGINT PRIMARY KEY AUTO_INCREMENT,

  -- context (match parents: BIGINT signed)
  sample_id   BIGINT NOT NULL,
  variant_id  BIGINT NULL,
  disease_id  BIGINT NULL,

  -- payload
  ann_key     VARCHAR(64)  NOT NULL,      -- e.g., 'zygosity','VAF','QC_flag','diagnosis','batch'
  ann_value   VARCHAR(255) NOT NULL,
  source      VARCHAR(64)  NULL,
  updated_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
              ON UPDATE CURRENT_TIMESTAMP,

  -- indexes
  KEY idx_sa_sample  (sample_id),
  KEY idx_sa_variant (variant_id),
  KEY idx_sa_disease (disease_id),

  -- de-dup per (sample, [variant?], [disease?], key)
  ctx_key VARCHAR(200) GENERATED ALWAYS AS (
    CONCAT(
      sample_id, ':',
      IFNULL(CAST(variant_id AS CHAR), '∅'), ':',
      IFNULL(CAST(disease_id AS CHAR), '∅'), ':',
      ann_key
    )
  ) STORED,
  UNIQUE KEY uq_sa_ctx (ctx_key),

  -- FKs (parents are BIGINT signed)
  CONSTRAINT fk_sa_sample  FOREIGN KEY (sample_id)
    REFERENCES sample(sample_id)
    ON DELETE CASCADE ON UPDATE CASCADE,

  CONSTRAINT fk_sa_variant FOREIGN KEY (variant_id)
    REFERENCES variants(variant_id)
    ON DELETE SET NULL ON UPDATE CASCADE,

  CONSTRAINT fk_sa_disease FOREIGN KEY (disease_id)
    REFERENCES disease(disease_id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci;
