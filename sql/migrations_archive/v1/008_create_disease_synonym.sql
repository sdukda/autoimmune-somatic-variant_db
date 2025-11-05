USE autoimmune_db;
CREATE TABLE IF NOT EXISTS disease_synonym(
    disease_synonym_id  BIGINT PRIMARY KEY AUTO_INCREMENT,
    disease_id          BIGINT NOT NULL,
    synonym             VARCHAR(128) NOT NULL,
    source              VARCHAR(32) NULL,
UNIQUE KEY uq_dis_syn (disease_id, synonym),
CONSTRAINT fk_dsyn_disease FOREIGN KEY (gene_id) REFERENCES diesease(disease_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
