CREATE TABLE IF NOT EXISTS disease_rollup (
  parent_disease_id BIGINT NOT NULL,
  child_disease_id  BIGINT NOT NULL,
  PRIMARY KEY (parent_disease_id, child_disease_id),
  CONSTRAINT fk_rollup_parent FOREIGN KEY (parent_disease_id) REFERENCES disease(disease_id),
  CONSTRAINT fk_rollup_child  FOREIGN KEY (child_disease_id)  REFERENCES disease(disease_id)
) ENGINE=InnoDB;

-- Add rollup: Celiac disease includes Refractory celiac disease
INSERT IGNORE INTO disease_rollup (parent_disease_id, child_disease_id)
VALUES (30, 9);

