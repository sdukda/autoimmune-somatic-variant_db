-- 001_create_all_tables.sql
-- Baseline schema for autoimmune_db (finalised ERD, simplified + detailed)
-- NOTE: run this after creating the database:
--   CREATE DATABASE autoimmune_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
--   USE autoimmune_db;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- Reference tables

CREATE TABLE reference_genome (
  ref_genome_id      BIGINT NOT NULL AUTO_INCREMENT,
  ref_genome_name    VARCHAR(32) NOT NULL,           -- e.g. 'GRCh37', 'GRCh38'
  source             VARCHAR(64) NULL,               -- e.g. 'Ensembl', 'UCSC'
  version            VARCHAR(16) NULL,               -- optional version string
  notes              TEXT NULL,
  PRIMARY KEY (ref_genome_id),
  UNIQUE KEY uq_ref_genome_name (ref_genome_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE disease (
  disease_id          BIGINT NOT NULL AUTO_INCREMENT,
  disease_name        VARCHAR(128) NOT NULL,
  disease_ontology_id VARCHAR(32) NULL,              -- e.g. DOID:7148
  notes               TEXT NULL,
  PRIMARY KEY (disease_id),
  UNIQUE KEY uq_disease_name (disease_name),
  KEY idx_disease_ontology_id (disease_ontology_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE cell_type (
  cell_type_id          BIGINT NOT NULL AUTO_INCREMENT,
  cell_type_name        VARCHAR(128) NOT NULL,       -- as written in the paper
  lineage               VARCHAR(32) NULL,            -- e.g. 'myeloid','lymphoid'
  cell_type_ontology_id VARCHAR(64) NULL,            -- e.g. CL:0000236
  notes                 TEXT NULL,
  PRIMARY KEY (cell_type_id),
  UNIQUE KEY uq_cell_type_name (cell_type_name),
  KEY idx_cell_type_ontology_id (cell_type_ontology_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Study / sample / experiment

CREATE TABLE study (
  study_id     BIGINT NOT NULL AUTO_INCREMENT,
  study_name   VARCHAR(255) NULL,
  pmid         VARCHAR(16) NULL,
  doi          VARCHAR(128) NULL,
  year         INT NULL,
  journal      VARCHAR(128) NULL,
  notes        TEXT NULL,
  PRIMARY KEY (study_id),
  UNIQUE KEY uq_study_pmid (pmid),
  UNIQUE KEY uq_study_doi  (doi),
  KEY idx_study_year (year)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE sample (
  sample_id          BIGINT NOT NULL AUTO_INCREMENT,
  disease_id         BIGINT NULL,
  patient_code       VARCHAR(32) NULL,
  tissue_source      VARCHAR(64) NOT NULL,           -- e.g. 'PBMC','colon biopsy'
  category           VARCHAR(32) NULL,               -- e.g. 'blood','tissue'
  sample_type        VARCHAR(64) NOT NULL,           -- e.g. 'bulk DNA','scDNA','scRNA'
  notes              TEXT NULL,
  PRIMARY KEY (sample_id),
  KEY idx_sample_disease_id (disease_id),
  CONSTRAINT fk_sample_disease
    FOREIGN KEY (disease_id) REFERENCES disease(disease_id)
      ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE sequencing_experiment (
  seq_exp_id   BIGINT NOT NULL AUTO_INCREMENT,
  study_id     BIGINT NOT NULL,
  sample_id    BIGINT NOT NULL,
  technology   ENUM('GWAS','Tapestri','GT_seq','WES','WGS','Other') NOT NULL,
  coverage     DECIMAL(10,2) NULL,
  notes        TEXT NULL,
  PRIMARY KEY (seq_exp_id),
  KEY idx_seqexp_study_id (study_id),
  KEY idx_seqexp_sample_id (sample_id),
  CONSTRAINT fk_seqexp_study
    FOREIGN KEY (study_id) REFERENCES study(study_id)
      ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_seqexp_sample
    FOREIGN KEY (sample_id) REFERENCES sample(sample_id)
      ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Gene / variant core

CREATE TABLE genes (
  gene_id        BIGINT NOT NULL AUTO_INCREMENT,
  ref_genome_id  BIGINT NOT NULL,
  gene_symbol    VARCHAR(32) NOT NULL,
  PRIMARY KEY (gene_id),
  UNIQUE KEY uq_gene_symbol_refgen (gene_symbol, ref_genome_id),
  KEY idx_genes_ref_genome_id (ref_genome_id),
  CONSTRAINT fk_genes_refgen
    FOREIGN KEY (ref_genome_id) REFERENCES reference_genome(ref_genome_id)
      ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE variants (
  variant_id       BIGINT NOT NULL AUTO_INCREMENT,
  ref_genome_id    BIGINT NOT NULL,
  gene_id          BIGINT NULL,
  chrom            VARCHAR(8) NOT NULL,
  pos              INT NOT NULL,
  ref              VARCHAR(255) NOT NULL,
  alt              VARCHAR(255) NOT NULL,
  variant_origin   VARCHAR(32) NULL,                 -- e.g. 'somatic','germline','CH'
  notes            TEXT NULL,
  PRIMARY KEY (variant_id),
  UNIQUE KEY uq_variant_coord (ref_genome_id, chrom, pos, ref, alt),
  KEY idx_variants_gene_id (gene_id),
  KEY idx_variants_ref_genome_id (ref_genome_id),
  CONSTRAINT fk_variants_refgen
    FOREIGN KEY (ref_genome_id) REFERENCES reference_genome(ref_genome_id)
      ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_variants_gene
    FOREIGN KEY (gene_id) REFERENCES genes(gene_id)
      ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE protein_domain (
  protein_domain_id BIGINT NOT NULL AUTO_INCREMENT,
  domain_name       VARCHAR(64) NOT NULL,
  domain_type       VARCHAR(64) NULL,
  notes             TEXT NULL,
  PRIMARY KEY (protein_domain_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Variant calls per experiment / cell type

CREATE TABLE sample_variant_call (
  call_id        BIGINT NOT NULL AUTO_INCREMENT,
  seq_exp_id     BIGINT NOT NULL,
  variant_id     BIGINT NOT NULL,
  cell_type_id   BIGINT NULL,                        -- may be NULL for bulk
  vaf            DECIMAL(4,3) NULL,                  -- 0.000–1.000
  depth          INT NULL,
  genotype_qual  INT NULL,
  variant_origin VARCHAR(32) NULL,                   -- per-sample interpretation (optional)
  notes          TEXT NULL,
  PRIMARY KEY (call_id),
  KEY idx_svc_seq_exp_id (seq_exp_id),
  KEY idx_svc_variant_id (variant_id),
  KEY idx_svc_cell_type_id (cell_type_id),
  CONSTRAINT fk_svc_seqexp
    FOREIGN KEY (seq_exp_id) REFERENCES sequencing_experiment(seq_exp_id)
      ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_svc_variant
    FOREIGN KEY (variant_id) REFERENCES variants(variant_id)
      ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_svc_cell_type
    FOREIGN KEY (cell_type_id) REFERENCES cell_type(cell_type_id)
      ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Annotation & functional validation

CREATE TABLE variant_annotation (
  ann_id        BIGINT NOT NULL AUTO_INCREMENT,
  variant_id    BIGINT NOT NULL,
  consequence   VARCHAR(64) NOT NULL,                -- e.g. 'missense_variant'
  hgvsp         VARCHAR(64) NULL,                    -- protein-level notation
  hgvsc         VARCHAR(128) NULL,                   -- cDNA-level notation
  source        VARCHAR(64) NULL,                    -- e.g. 'VEP','SnpEff'
  version       VARCHAR(32) NULL,                    -- annotation tool version
  notes         TEXT NULL,
  PRIMARY KEY (ann_id),
  KEY idx_ann_variant_id (variant_id),
  CONSTRAINT fk_ann_variant
    FOREIGN KEY (variant_id) REFERENCES variants(variant_id)
      ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE functional_validation (
  validation_id  BIGINT NOT NULL AUTO_INCREMENT,
  call_id        BIGINT NULL,
  variant_id     BIGINT NOT NULL,
  assay_type     VARCHAR(64) NOT NULL,              -- e.g. 'CRISPR KO','luciferase'
  result         VARCHAR(32) NULL,                  -- e.g. 'LOF','GOF','no_effect'
  notes          TEXT NULL,
  PRIMARY KEY (validation_id),
  KEY idx_fv_call_id (call_id),
  KEY idx_fv_variant_id (variant_id),
  CONSTRAINT fk_fv_call
    FOREIGN KEY (call_id) REFERENCES sample_variant_call(call_id)
      ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_fv_variant
    FOREIGN KEY (variant_id) REFERENCES variants(variant_id)
      ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;
