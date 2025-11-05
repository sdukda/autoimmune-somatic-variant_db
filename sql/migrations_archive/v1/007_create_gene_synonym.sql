USE autoimmune_db;
CREATE TABLE IF NOT EXISTS gene_synonym (
  gene_synonym_id BIGINT PRIMARY KEY AUTO_INCREMENT,
  gene_id BIGINT NOT NULL,
  synonym VARCHAR(64) NOT NULL,
  source  VARCHAR(32) NULL,
  UNIQUE KEY uq_gene_syn (gene_id, synonym),
  CONSTRAINT fk_gsyn_gene FOREIGN KEY (gene_id) REFERENCES genes(gene_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
