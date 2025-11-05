-- 1) LOOKUPS / REFS FIRST
-- 1.1 reference_genome
CREATE TABLE IF NOT EXISTS reference_genome (
  ref_genome_id   INT PRIMARY KEY AUTO_INCREMENT,
  assembly_name   VARCHAR(32) NOT NULL,   -- e.g., GRCh38
  version         VARCHAR(16) NULL,
  CONSTRAINT uq_reference_genome UNIQUE (assembly_name, version)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 1.2 variant_type
CREATE TABLE IF NOT EXISTS variant_type (
  variant_type_id INT PRIMARY KEY AUTO_INCREMENT,
  code            VARCHAR(16) NOT NULL,   -- SNV, INDEL, SV, CNV
  label           VARCHAR(64) NULL,
  CONSTRAINT uq_variant_type_code UNIQUE (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 1.3 genes
CREATE TABLE IF NOT EXISTS genes (
  gene_id     BIGINT PRIMARY KEY AUTO_INCREMENT,
  gene_symbol VARCHAR(32) NOT NULL,
  CONSTRAINT uq_genes_symbol UNIQUE (gene_symbol)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 1.4 transcripts
CREATE TABLE IF NOT EXISTS transcripts (
  transcript_id VARCHAR(20) PRIMARY KEY,             -- e.g., ENST..., NM_...
  gene_id       BIGINT NOT NULL,
  source        VARCHAR(16) NOT NULL,                -- RefSeq / Ensembl
  accession     VARCHAR(20) NOT NULL,
  version       VARCHAR(8)  NULL,
  CONSTRAINT fk_transcripts_gene FOREIGN KEY (gene_id)
    REFERENCES genes(gene_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT uq_transcripts_src_acc_ver UNIQUE (source, accession, version),
  KEY idx_transcripts_gene (gene_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 1.5 disease
CREATE TABLE IF NOT EXISTS disease (
  disease_id      BIGINT PRIMARY KEY AUTO_INCREMENT,
  disease_name    VARCHAR(128) NOT NULL,
   ontology_source VARCHAR(16)  NULL,
  ontology_id     VARCHAR(32)  NULL,
  CONSTRAINT uq_disease_name UNIQUE (disease_name),
  CONSTRAINT uq_disease_ontology UNIQUE (ontology_source, ontology_id),
  KEY idx_disease_name (disease_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 1.6 patient (depends on disease)
CREATE TABLE IF NOT EXISTS patient (
  patient_id                   BIGINT PRIMARY KEY AUTO_INCREMENT,
  primary_diagnosis_disease_id BIGINT NOT NULL,
  sex                          VARCHAR(16) NOT NULL DEFAULT 'UNKNOWN',  -- MALE/FEMALE/UNKNOWN
  age_years                    SMALLINT NULL,
  CONSTRAINT fk_patient_diagnosis FOREIGN KEY (primary_diagnosis_disease_id)
    REFERENCES disease(disease_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  KEY idx_patient_diagnosis (primary_diagnosis_disease_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 1.7 study
CREATE TABLE IF NOT EXISTS study (
  study_id    BIGINT PRIMARY KEY AUTO_INCREMENT,
  study_name  VARCHAR(128) NOT NULL,
  description TEXT NULL,
  CONSTRAINT uq_study_name UNIQUE (study_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 1.8 technology
CREATE TABLE IF NOT EXISTS technology (
  technology_id INT PRIMARY KEY AUTO_INCREMENT,
  platform      VARCHAR(64) NOT NULL,           -- e.g., Mission Bio Tapestri
  CONSTRAINT uq_technology_platform UNIQUE (platform)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 1.9 reference_paper
CREATE TABLE IF NOT EXISTS reference_paper (
  ref_paper_id BIGINT PRIMARY KEY AUTO_INCREMENT,
  pmid         INT        NULL,
  doi          VARCHAR(64) NULL,
  year         SMALLINT   NULL,
  title        VARCHAR(512) NULL,
  CONSTRAINT uq_refpaper_pmid UNIQUE (pmid),
  CONSTRAINT uq_refpaper_doi  UNIQUE (doi),
  KEY idx_refpaper_year (year)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2) CORE HUB
-- 2.1 variants
CREATE TABLE IF NOT EXISTS variants (
  variant_id      BIGINT PRIMARY KEY AUTO_INCREMENT,
  ref_genome_id   INT NOT NULL,
  chrom           VARCHAR(8)  NOT NULL,
  pos             INT         NOT NULL,
  ref             VARCHAR(2048) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  alt             VARCHAR(2048) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  variant_type_id INT NOT NULL,

  -- generated hash for (ref, alt)
  ref_alt_hash    BINARY(32)
    GENERATED ALWAYS AS (UNHEX(SHA2(CONCAT(ref, _ascii'#', alt), 256))) STORED,

  CONSTRAINT fk_variants_build FOREIGN KEY (ref_genome_id)
    REFERENCES reference_genome(ref_genome_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_variants_vtype FOREIGN KEY (variant_type_id)
    REFERENCES variant_type(variant_type_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,

  CONSTRAINT uq_variant_build_pos_hash UNIQUE (ref_genome_id, chrom, pos, ref_alt_hash),
  KEY idx_variants_build_chr_pos (ref_genome_id, chrom, pos)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3) ANNOTATIONS & FREQUENCIES
-- 3.1 variant_annotation
CREATE TABLE IF NOT EXISTS variant_annotation (
  ann_id        BIGINT PRIMARY KEY AUTO_INCREMENT,
  variant_id    BIGINT NOT NULL,
  gene_id       BIGINT NULL,
  transcript_id VARCHAR(20) NULL,
  source_name   VARCHAR(32) NOT NULL,          -- e.g., VEP, snpEff, ClinVar, COSMIC
  consequence   VARCHAR(64) NULL,              -- e.g., missense_variant
  hgvsc         VARCHAR(64) NULL,
  hgvsp         VARCHAR(64) NULL,
  polyphen_pred VARCHAR(32) NULL,
  polyphen_score DECIMAL(4,3) NULL,

  CONSTRAINT fk_va_variant FOREIGN KEY (variant_id)
    REFERENCES variants(variant_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_va_gene FOREIGN KEY (gene_id)
    REFERENCES genes(gene_id)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_va_transcript FOREIGN KEY (transcript_id)
    REFERENCES transcripts(transcript_id)
    ON DELETE SET NULL ON UPDATE CASCADE,

  KEY idx_va_variant   (variant_id),
  KEY idx_va_gene      (gene_id),
  KEY idx_va_transcript(transcript_id),
  -- prevent duplicate lines per tool/transcript combo for same variant (optional but useful)
  UNIQUE KEY uq_va_tool_tx (variant_id, source_name, transcript_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3.2 variant_freq 
CREATE TABLE IF NOT EXISTS variant_freq (
  variant_freq_id BIGINT PRIMARY KEY AUTO_INCREMENT,
  variant_id      BIGINT NOT NULL,
  cohort_name     VARCHAR(64) NOT NULL,   -- e.g., gnomAD, 1000G
  population_code VARCHAR(16) NULL,       -- optional subpopulation (e.g., NFE)
  af              DECIMAL(6,5) NOT NULL,  -- 0.00000–1.00000
  source_version  VARCHAR(32) NULL,

  CONSTRAINT fk_vf_variant FOREIGN KEY (variant_id)
    REFERENCES variants(variant_id)
    ON DELETE CASCADE ON UPDATE CASCADE,

  CONSTRAINT uq_vf_variant_cohort_pop UNIQUE (variant_id, cohort_name, population_code),
  KEY idx_vf_variant (variant_id),
  KEY idx_vf_cohort  (cohort_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4) EXPERIMENTS & DERIVED ENTITIES
-- 4.1 sequencing_experiment
CREATE TABLE IF NOT EXISTS sequencing_experiment (
  sequencing_experiment_id BIGINT PRIMARY KEY AUTO_INCREMENT,
  study_id                 BIGINT NOT NULL,
  patient_id               BIGINT NOT NULL,
  technology_id            INT    NULL,
  experiment_name          VARCHAR(64) NOT NULL,

  CONSTRAINT fk_se_study FOREIGN KEY (study_id)
    REFERENCES study(study_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_se_patient FOREIGN KEY (patient_id)
    REFERENCES patient(patient_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_se_technology FOREIGN KEY (technology_id)
    REFERENCES technology(technology_id)
    ON DELETE SET NULL ON UPDATE CASCADE,

  CONSTRAINT uq_se_study_expname UNIQUE (study_id, experiment_name),
  KEY idx_se_patient (patient_id),
  KEY idx_se_study   (study_id),
  KEY idx_se_tech    (technology_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4.2 cell_type 
CREATE TABLE IF NOT EXISTS cell_type (
  cell_type_id             BIGINT PRIMARY KEY AUTO_INCREMENT,
  sequencing_experiment_id BIGINT NOT NULL,
  immune_cell_type         VARCHAR(64) NOT NULL,      -- e.g., CD4, CD8, Bcell
  enrichment_score         DECIMAL(5,4) NULL,

  CONSTRAINT fk_ct_se FOREIGN KEY (sequencing_experiment_id)
    REFERENCES sequencing_experiment(sequencing_experiment_id)
    ON DELETE CASCADE ON UPDATE CASCADE,

  CONSTRAINT uq_ct_se_type UNIQUE (sequencing_experiment_id, immune_cell_type),
  KEY idx_ct_se (sequencing_experiment_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4.3 sample_variant_call
CREATE TABLE IF NOT EXISTS sample_variant_call (
  sample_variant_call_id   BIGINT PRIMARY KEY AUTO_INCREMENT,
  sequencing_experiment_id BIGINT NOT NULL,
  variant_id               BIGINT NOT NULL,
  cell_type_id             BIGINT NULL,
  genotype                 VARCHAR(8)  NOT NULL,      -- e.g., 0/1, 1/1
  dp                       INT NULL,                  -- depth
  gq                       INT NULL,                  -- genotype quality
  filters                  VARCHAR(255) NULL,         -- PASS / low_vaf / ...
  caller_name              VARCHAR(64)  NULL,
  call_date                DATE         NULL,

  CONSTRAINT fk_svc_se FOREIGN KEY (sequencing_experiment_id)
    REFERENCES sequencing_experiment(sequencing_experiment_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_svc_variant FOREIGN KEY (variant_id)
    REFERENCES variants(variant_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_svc_celltype FOREIGN KEY (cell_type_id)
    REFERENCES cell_type(cell_type_id)
    ON DELETE SET NULL ON UPDATE CASCADE,

  KEY idx_svc_se       (sequencing_experiment_id),
  KEY idx_svc_variant  (variant_id),
  KEY idx_svc_celltype (cell_type_id),
  -- avoid duplicates of the same (run, variant, subset)
  UNIQUE KEY uq_svc_se_var_type (sequencing_experiment_id, variant_id, cell_type_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4.4 sample_variant_summary 
CREATE TABLE IF NOT EXISTS sample_variant_summary (
  sample_variant_summary_id BIGINT PRIMARY KEY AUTO_INCREMENT,
  sequencing_experiment_id  BIGINT NOT NULL,
  variant_id                BIGINT NOT NULL,
  cell_type_id              BIGINT NULL,
  evidence_source           VARCHAR(128) NULL,        -- e.g., COSMIC, ClinVar, Internal
  ref_paper_id              BIGINT NULL,

  CONSTRAINT fk_svsum_se FOREIGN KEY (sequencing_experiment_id)
    REFERENCES sequencing_experiment(sequencing_experiment_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_svsum_variant FOREIGN KEY (variant_id)
    REFERENCES variants(variant_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_svsum_celltype FOREIGN KEY (cell_type_id)
    REFERENCES cell_type(cell_type_id)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_svsum_refpaper FOREIGN KEY (ref_paper_id)
    REFERENCES reference_paper(ref_paper_id)
    ON DELETE SET NULL ON UPDATE CASCADE,

  CONSTRAINT uq_svsum_se_var_type UNIQUE (sequencing_experiment_id, variant_id, cell_type_id),

  KEY idx_svsum_se       (sequencing_experiment_id),
  KEY idx_svsum_variant  (variant_id),
  KEY idx_svsum_celltype (cell_type_id),
  KEY idx_svsum_refpaper (ref_paper_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS = 1;
