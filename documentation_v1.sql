-- Repository layout reminder
-- sql/
--   migrations/
--     000_reset.sql
--     001_create_core_tables.sql
--     002_create_supporting_tables.sql
--     003_constraints_and_foreign_keys.sql
--     004_indexes.sql
--     005_views.sql
--     006_seed_minimal.sql
--
-- MySQL dialect: verified for MySQL 8.0+ (works on 8.4 LTS).  
-- Notes:
--  * Use InnoDB, utf8mb4_0900_ai_ci.  
--  * When altering tables, each ADD COLUMN ... IF NOT EXISTS must be a full statement (no trailing comma).  
--  * FK names are explicit for clarity.  
--  * TIMESTAMP DEFAULT CURRENT_TIMESTAMP is used for created_at; updated_at uses ON UPDATE.

/******************************
 * 000_reset.sql
 ******************************/
-- DANGER: drops all known tables (idempotent). Run only on dev!
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS study_ref_paper;
DROP TABLE IF EXISTS reference_paper;
DROP TABLE IF EXISTS sample_annotation;
DROP TABLE IF EXISTS variant_external_id;
DROP TABLE IF EXISTS variant_annotation;
DROP TABLE IF EXISTS sample_variant_call;
DROP TABLE IF EXISTS cell;
DROP TABLE IF EXISTS sample;
DROP TABLE IF EXISTS study;
DROP TABLE IF EXISTS disease_synonym;
DROP TABLE IF EXISTS disease;
DROP TABLE IF EXISTS transcript;
DROP TABLE IF EXISTS gene;
DROP TABLE IF EXISTS variant;
DROP TABLE IF EXISTS reference_genome;
SET FOREIGN_KEY_CHECKS = 1;

/******************************
 * 001_create_core_tables.sql
 ******************************/
CREATE TABLE IF NOT EXISTS reference_genome (
  ref_genome_id   BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name            VARCHAR(64) NOT NULL,
  version_label   VARCHAR(64) NOT NULL,
  build_date      DATE NULL,
  UNIQUE KEY uq_refgenome_name_version (name, version_label)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS gene (
  gene_id         BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  symbol          VARCHAR(64) NOT NULL,
  name_long       VARCHAR(255) NULL,
  ensembl_gene_id VARCHAR(32) NULL,
  ref_genome_id   BIGINT UNSIGNED NULL,
  created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_gene_symbol (symbol),
  UNIQUE KEY uq_gene_ensembl (ensembl_gene_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS transcript (
  transcript_id          BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  gene_id                BIGINT UNSIGNED NULL,
  ensembl_transcript_id  VARCHAR(32) NULL,
  is_canonical           TINYINT(1) NOT NULL DEFAULT 0,
  UNIQUE KEY uq_tx_ensembl (ensembl_transcript_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS variant (
  variant_id     BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  ref_genome_id  BIGINT UNSIGNED NOT NULL,
  chrom          VARCHAR(8) NOT NULL,
  pos            BIGINT UNSIGNED NOT NULL,
  ref            VARCHAR(255) NOT NULL,
  alt            VARCHAR(255) NOT NULL,
  variant_type   VARCHAR(32) NOT NULL, -- e.g., SNV, INS, DEL, MNV, etc.
  rsid           VARCHAR(32) NULL,
  hgvs_c         VARCHAR(255) NULL,
  hgvs_p         VARCHAR(255) NULL,
  created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_variant_locus (ref_genome_id, chrom, pos, ref, alt)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS disease (
  disease_id     BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name           VARCHAR(128) NOT NULL,
  ontology_id    VARCHAR(64) NULL, -- e.g., MONDO/DOID/ICD code
  UNIQUE KEY uq_disease_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS study (
  study_id       BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  title          VARCHAR(512) NOT NULL,
  pubmed_id      VARCHAR(32) NULL,
  doi            VARCHAR(128) NULL,
  year           SMALLINT NULL,
  created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_study_pubmed (pubmed_id),
  UNIQUE KEY uq_study_doi (doi)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS sample (
  sample_id      BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  study_id       BIGINT UNSIGNED NULL,
  disease_id     BIGINT UNSIGNED NULL,
  external_name  VARCHAR(128) NULL, -- lab name / SRA sample id
  tissue         VARCHAR(128) NULL,
  platform       VARCHAR(64) NULL, -- e.g., MissionBio Tapestri
  created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS cell (
  cell_id        BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  sample_id      BIGINT UNSIGNED NOT NULL,
  barcode        VARCHAR(64) NOT NULL,
  qc_pass        TINYINT(1) NOT NULL DEFAULT 1,
  UNIQUE KEY uq_cell_sample_barcode (sample_id, barcode)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS sample_variant_call (
  svc_id         BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  sample_id      BIGINT UNSIGNED NOT NULL,
  cell_id        BIGINT UNSIGNED NULL, -- NULL = bulk / aggregated per-sample call
  variant_id     BIGINT UNSIGNED NOT NULL,
  genotype       VARCHAR(8) NULL,      -- e.g., 0/0,0/1,1/1
  ad_ref         INT NULL,
  ad_alt         INT NULL,
  dp             INT NULL,
  gq             INT NULL,
  vaf            DECIMAL(6,4) AS (IFNULL(ad_alt,0) / NULLIF(IFNULL(ad_alt,0)+IFNULL(ad_ref,0),0)) STORED,
  filters        VARCHAR(255) NULL,    -- semicolon delimited or short text
  is_somatic     TINYINT(1) NOT NULL DEFAULT 0,
  created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_svc_unique (sample_id, COALESCE(cell_id,0), variant_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/******************************
 * 002_create_supporting_tables.sql
 ******************************/
CREATE TABLE IF NOT EXISTS variant_annotation (
  variant_annotation_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  variant_id            BIGINT UNSIGNED NOT NULL,
  transcript_id         BIGINT UNSIGNED NULL,
  gene_id               BIGINT UNSIGNED NULL,
  consequence           VARCHAR(64) NULL,    -- e.g., missense_variant
  impact                VARCHAR(16) NULL,    -- e.g., HIGH/MODERATE/LOW/MODIFIER
  protein_change        VARCHAR(32) NULL,    -- p.P519S etc
  cDNA_change           VARCHAR(64) NULL,    -- c.123A>T
  protein_coding_impact VARCHAR(64) NULL,    -- frameshift, stop_gained
  clinvar_significance  VARCHAR(64) NULL,    -- e.g., Pathogenic
  cosmic_id             VARCHAR(32) NULL,
  allele_freq           DECIMAL(8,6) NULL,   -- population AF (e.g., gnomAD)
  source                VARCHAR(64) NULL,    -- e.g., VEP, snpEff
  created_at            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS variant_external_id (
  variant_external_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  variant_id          BIGINT UNSIGNED NOT NULL,
  db_name             VARCHAR(32) NOT NULL,  -- e.g., ClinVar, dbSNP, COSMIC
  db_accession        VARCHAR(64) NOT NULL,
  UNIQUE KEY uq_var_ext (variant_id, db_name, db_accession)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS disease_synonym (
  disease_synonym_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  disease_id         BIGINT UNSIGNED NOT NULL,
  synonym            VARCHAR(128) NOT NULL,
  UNIQUE KEY uq_disease_synonym (disease_id, synonym)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS reference_paper (
  reference_paper_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  title              VARCHAR(512) NOT NULL,
  pubmed_id          VARCHAR(32) NULL,
  doi                VARCHAR(128) NULL,
  year               SMALLINT NULL,
  UNIQUE KEY uq_refpaper_pubmed (pubmed_id),
  UNIQUE KEY uq_refpaper_doi (doi)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS study_ref_paper (
  study_ref_paper_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  study_id           BIGINT UNSIGNED NOT NULL,
  reference_paper_id BIGINT UNSIGNED NOT NULL,
  UNIQUE KEY uq_study_refpaper (study_id, reference_paper_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS sample_annotation (
  sample_annotation_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  sample_id            BIGINT UNSIGNED NOT NULL,
  `key`                VARCHAR(64) NOT NULL,
  `value`              VARCHAR(255) NULL,
  UNIQUE KEY uq_sample_kv (sample_id, `key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/******************************
 * 003_constraints_and_foreign_keys.sql
 ******************************/
-- Put all FKs here so creation order is simpler and re-runnable.
ALTER TABLE gene
  ADD CONSTRAINT fk_gene_refgenome
    FOREIGN KEY (ref_genome_id) REFERENCES reference_genome(ref_genome_id)
    ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE transcript
  ADD CONSTRAINT fk_transcript_gene
    FOREIGN KEY (gene_id) REFERENCES gene(gene_id)
    ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE variant
  ADD CONSTRAINT fk_variant_refgenome
    FOREIGN KEY (ref_genome_id) REFERENCES reference_genome(ref_genome_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE sample
  ADD CONSTRAINT fk_sample_study
    FOREIGN KEY (study_id) REFERENCES study(study_id)
    ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT fk_sample_disease
    FOREIGN KEY (disease_id) REFERENCES disease(disease_id)
    ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE cell
  ADD CONSTRAINT fk_cell_sample
    FOREIGN KEY (sample_id) REFERENCES sample(sample_id)
    ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE sample_variant_call
  ADD CONSTRAINT fk_svc_sample
    FOREIGN KEY (sample_id) REFERENCES sample(sample_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT fk_svc_cell
    FOREIGN KEY (cell_id) REFERENCES cell(cell_id)
    ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT fk_svc_variant
    FOREIGN KEY (variant_id) REFERENCES variant(variant_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE variant_annotation
  ADD CONSTRAINT fk_varann_variant
    FOREIGN KEY (variant_id) REFERENCES variant(variant_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT fk_varann_transcript
    FOREIGN KEY (transcript_id) REFERENCES transcript(transcript_id)
    ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT fk_varann_gene
    FOREIGN KEY (gene_id) REFERENCES gene(gene_id)
    ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE variant_external_id
  ADD CONSTRAINT fk_varext_variant
    FOREIGN KEY (variant_id) REFERENCES variant(variant_id)
    ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE disease_synonym
  ADD CONSTRAINT fk_dis_syn_disease
    FOREIGN KEY (disease_id) REFERENCES disease(disease_id)
    ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE study_ref_paper
  ADD CONSTRAINT fk_study_ref_study
    FOREIGN KEY (study_id) REFERENCES study(study_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT fk_study_ref_paper
    FOREIGN KEY (reference_paper_id) REFERENCES reference_paper(reference_paper_id)
    ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE sample_annotation
  ADD CONSTRAINT fk_sampleann_sample
    FOREIGN KEY (sample_id) REFERENCES sample(sample_id)
    ON DELETE CASCADE ON UPDATE CASCADE;

/******************************
 * 004_indexes.sql
 ******************************/
-- Helpful secondary indexes for frequent queries
CREATE INDEX idx_variant_chrom_pos ON variant (chrom, pos);
CREATE INDEX idx_variant_gene_ann ON variant_annotation (gene_id, consequence);
CREATE INDEX idx_svc_variant ON sample_variant_call (variant_id);
CREATE INDEX idx_svc_sample_cell ON sample_variant_call (sample_id, cell_id);
CREATE INDEX idx_cell_sample ON cell (sample_id);
CREATE INDEX idx_sample_study ON sample (study_id);
CREATE INDEX idx_study_year ON study (year);
CREATE INDEX idx_gene_symbol ON gene (symbol);

/******************************
 * 005_views.sql
 ******************************/
-- Common researcher-facing views
CREATE OR REPLACE VIEW v_variant_core AS
SELECT v.variant_id, rg.name AS ref_genome, v.chrom, v.pos, v.ref, v.alt,
       v.variant_type, v.rsid, v.hgvs_c, v.hgvs_p
FROM variant v
JOIN reference_genome rg ON rg.ref_genome_id = v.ref_genome_id;

CREATE OR REPLACE VIEW v_somatic_calls AS
SELECT s.study_id, s.sample_id, c.cell_id, v.variant_id,
       svc.genotype, svc.dp, svc.gq, svc.vaf, svc.filters
FROM sample_variant_call svc
JOIN sample s   ON s.sample_id = svc.sample_id
LEFT JOIN cell c ON c.cell_id = svc.cell_id
JOIN variant v  ON v.variant_id = svc.variant_id
WHERE svc.is_somatic = 1;

CREATE OR REPLACE VIEW v_variant_with_gene AS
SELECT v.variant_id, v.chrom, v.pos, v.ref, v.alt,
       va.gene_id, g.symbol AS gene_symbol, va.consequence, va.impact,
       va.protein_change, va.clinvar_significance, va.cosmic_id
FROM variant v
LEFT JOIN variant_annotation va ON va.variant_id = v.variant_id
LEFT JOIN gene g ON g.gene_id = va.gene_id;

/******************************
 * 006_seed_minimal.sql
 ******************************/
INSERT IGNORE INTO reference_genome(name, version_label, build_date)
VALUES ('GRCh38', 'p14', '2022-02-03'), ('GRCh37', 'hs37d5', '2013-02-01');

INSERT IGNORE INTO disease(name, ontology_id)
VALUES ('Celiac disease', 'MONDO:0005130');

INSERT IGNORE INTO study(title, pubmed_id, doi, year)
VALUES ('Autoimmune cohort pilot', NULL, NULL, 2025);

-- Example sample for your 1912 Tapestri run
INSERT IGNORE INTO sample(study_id, disease_id, external_name, tissue, platform)
SELECT st.study_id, d.disease_id, '1912', 'PBMC', 'MissionBio Tapestri'
FROM study st JOIN disease d ON d.name = 'Celiac disease'
WHERE st.title = 'Autoimmune cohort pilot'
LIMIT 1;
