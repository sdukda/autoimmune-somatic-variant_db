-- === CORE ENTITIES ===
USE autoimmune_db;

CREATE TABLE genes (
  gene_id           BIGINT PRIMARY KEY AUTO_INCREMENT,
  gene_symbol       VARCHAR(32) NOT NULL,
  ensembl_gene_id   VARCHAR(20) NULL,
  hgnc_id           INT NULL,
  UNIQUE (gene_symbol),
  UNIQUE (ensembl_gene_id),
  UNIQUE (hgnc_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE transcripts (
  transcript_id     VARCHAR(20) PRIMARY KEY,   -- ENST... / NM_...
  gene_id           BIGINT NOT NULL,
  source            VARCHAR(16) NOT NULL,      -- Ensembl/RefSeq
  accession         VARCHAR(20) NOT NULL,      -- ENST... / NM_...
  version           VARCHAR(8)  NULL,
  UNIQUE (source, accession, version),
  KEY idx_transcripts_gene (gene_id),
  CONSTRAINT fk_transcripts_gene
    FOREIGN KEY (gene_id) REFERENCES genes(gene_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE disease (
  disease_id        BIGINT PRIMARY KEY AUTO_INCREMENT,
  disease_name      VARCHAR(128) NOT NULL,
  ontology_source   VARCHAR(16) NULL,   -- MONDO, EFO, DOID...
  ontology_id       VARCHAR(32) NULL,
  UNIQUE (ontology_source, ontology_id),
  KEY idx_disease_name (disease_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE ref_paper (
  ref_paper_id      BIGINT PRIMARY KEY AUTO_INCREMENT,
  title             VARCHAR(512) NOT NULL,
  pmid              INT NULL,
  doi               VARCHAR(128) NULL,
  year              SMALLINT NULL,
  journal           VARCHAR(512) NULL,
  UNIQUE (pmid),
  UNIQUE (doi),
  KEY idx_ref_year (year)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE study (
  study_id          BIGINT PRIMARY KEY AUTO_INCREMENT,
  name              VARCHAR(128) NOT NULL,
  description       TEXT NULL,
  UNIQUE (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE sample (
  sample_id         BIGINT PRIMARY KEY AUTO_INCREMENT,
  study_id          BIGINT NOT NULL,
  subject_id        BIGINT NULL,    -- if you later add a subject table
  technology_id     INT    NULL,
  sample_name       VARCHAR(64) NOT NULL,
  UNIQUE (study_id, sample_name),
  KEY idx_sample_study (study_id),
  KEY idx_sample_tech  (technology_id),
  CONSTRAINT fk_sample_study
    FOREIGN KEY (study_id) REFERENCES study(study_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sample_technology
    FOREIGN KEY (technology_id) REFERENCES technology(technology_id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE cell (
  cell_id           BIGINT PRIMARY KEY AUTO_INCREMENT,
  sample_id         BIGINT NOT NULL,
  barcode           VARCHAR(64) NOT NULL,
  UNIQUE (sample_id, barcode),
  KEY idx_cell_sample (sample_id),
  CONSTRAINT fk_cell_sample
    FOREIGN KEY (sample_id) REFERENCES sample(sample_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE variants (
  variant_id        BIGINT PRIMARY KEY AUTO_INCREMENT,
  ref_genome_id     INT NOT NULL,
  chrom             VARCHAR(8)  NOT NULL,
  pos               INT NOT NULL,
  
-- ref/alt may be long (SVs/indels); store as ASCII (A/C/G/T/N/- …)
  ref               VARCHAR(2048) CHARACTER SET ascii NOT NULL,
  alt               VARCHAR(2048) CHARACTER SET ascii NOT NULL,
  variant_type_id   INT NOT NULL,

  -- Deterministic hash so we can enforce uniqueness without indexing huge strings
  ref_alt_hash      BINARY(32)
    GENERATED ALWAYS AS (UNHEX(SHA2(CONCAT(ref, '#', alt), 256))) STORED,
  
  -- Uniqueness per build/chrom/pos + ref/alt content
  UNIQUE KEY uq_variant_build_pos_hash (ref_genome_id, chrom, pos, ref_alt_hash),

  -- Helpful range/index scans
  KEY idx_variants_build_chr_pos (ref_genome_id, chrom, pos),

  CONSTRAINT fk_variants_build
    FOREIGN KEY (ref_genome_id) REFERENCES reference_genome(ref_genome_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_variants_vtype
    FOREIGN KEY (variant_type_id) REFERENCES variant_type(variant_type_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

