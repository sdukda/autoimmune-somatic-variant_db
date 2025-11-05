-- === RELATIONSHIPS / BIOLOGY ===
USE autoimmune_db;

CREATE TABLE variant_annotation (
  ann_id            BIGINT PRIMARY KEY AUTO_INCREMENT,
  variant_id        BIGINT NOT NULL,
  transcript_id     VARCHAR(20) NOT NULL,
  gene_id           BIGINT NOT NULL,
  impact_id         INT NOT NULL,              -- e.g., missense_variant
  impact_severity_id INT NOT NULL,             -- LOW/MODERATE/HIGH/UNKNOWN
  hgvsc             VARCHAR(255) NULL,         -- e.g., NM_......:c.123A>G
  hgvsp             VARCHAR(255) NULL,         -- e.g., NP_......:p.Lys41Arg
  -- per-transcript grain:
  UNIQUE (variant_id, transcript_id),
  KEY idx_va_variant (variant_id),
  KEY idx_va_transcript (transcript_id),
  KEY idx_va_gene (gene_id),
  KEY idx_va_impact (impact_id),
  KEY idx_va_severity (impact_severity_id),
  CONSTRAINT fk_va_variant
    FOREIGN KEY (variant_id) REFERENCES variants(variant_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_va_transcript
    FOREIGN KEY (transcript_id) REFERENCES transcripts(transcript_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_va_gene
    FOREIGN KEY (gene_id) REFERENCES genes(gene_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_va_impact
    FOREIGN KEY (impact_id) REFERENCES variant_impact(impact_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_va_severity
    FOREIGN KEY (impact_severity_id) REFERENCES impact_severity(impact_severity_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE annotation_prediction (
  annotation_id     BIGINT PRIMARY KEY,   -- PK & FK enforces 1:1 with variant_annotation
  polyphen_pred     ENUM('benign','possibly_damaging','probably_damaging','unknown') NULL,
  polyphen_score    DECIMAL(4,3) NULL,
  CONSTRAINT fk_ap_annotation
    FOREIGN KEY (annotation_id) REFERENCES variant_annotation(ann_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE external_annotation (
  external_annotation_id    BIGINT PRIMARY KEY AUTO_INCREMENT,
  variant_id                BIGINT NOT NULL,   
  source_name               VARCHAR(32) NOT NULL, -- e.g., 'dbSNP','ClinVar','gnomAD','COSMIC'
  external_id               VARCHAR(64) NOT NULL, -- e.g., rsID / VCV / gnomAD key / COSMIC ID
  url                       VARCHAR(255) NULL,
  last_verified_at          DATETIME NULL,
  UNIQUE (variant_id, source_name, external_id),
  KEY idx_ea_variant (variant_id),
  KEY idx_ea_source (source_name),
 
  CONSTRAINT fk_ea_variant
    FOREIGN KEY (variant_id) REFERENCES variants(variant_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE gene_overlap (
  gene_overlap_id   BIGINT PRIMARY KEY AUTO_INCREMENT,
  variant_id        BIGINT NOT NULL,
  gene_id           BIGINT NOT NULL,
  overlap_kind      ENUM('exonic','intronic','utr5','utr3','splice_region','upstream','downstream') NOT NULL,
  UNIQUE (variant_id, gene_id, overlap_kind),
  KEY idx_go_variant (variant_id),
  KEY idx_go_gene    (gene_id),
  CONSTRAINT fk_go_variant FOREIGN KEY (variant_id) REFERENCES variants(variant_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_go_gene    FOREIGN KEY (gene_id)    REFERENCES genes(gene_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE study_variant (
  study_variant_id  BIGINT PRIMARY KEY AUTO_INCREMENT,
  study_id          BIGINT NOT NULL,
  variant_id        BIGINT NOT NULL,
  UNIQUE (study_id, variant_id),
  KEY idx_sv_variant (variant_id),
  KEY idx_sv_study   (study_id),
  CONSTRAINT fk_sv_study   FOREIGN KEY (study_id)  REFERENCES study(study_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_sv_variant FOREIGN KEY (variant_id) REFERENCES variants(variant_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE study_ref_paper (
  study_id          BIGINT NOT NULL,
  ref_paper_id      BIGINT NOT NULL,
  PRIMARY KEY (study_id, ref_paper_id),
  KEY idx_srp_study (study_id),
  KEY idx_srp_ref   (ref_paper_id),
  CONSTRAINT fk_srp_study FOREIGN KEY (study_id) REFERENCES study(study_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_srp_ref   FOREIGN KEY (ref_paper_id) REFERENCES ref_paper(ref_paper_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE evidence (
  evidence_id       BIGINT PRIMARY KEY AUTO_INCREMENT,
  variant_id        BIGINT NOT NULL,        -- either variant or fusion (if you add fusions)
  disease_id        BIGINT NULL,
  ref_paper_id      BIGINT NOT NULL,
  study_id          BIGINT NULL,
  evidence_type     ENUM('genetic','functional', 'clinical','literature', 'other') NOT NULL,
  KEY idx_ev_variant (variant_id),
  KEY idx_ev_disease (disease_id),
  KEY idx_ev_ref     (ref_paper_id),
  KEY idx_ev_study   (study_id),
  CONSTRAINT fk_ev_variant FOREIGN KEY (variant_id) REFERENCES variants(variant_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_ev_disease FOREIGN KEY (disease_id) REFERENCES disease(disease_id)
    ON DELETE SET NULL  ON UPDATE CASCADE,
  CONSTRAINT fk_ev_ref     FOREIGN KEY (ref_paper_id) REFERENCES ref_paper(ref_paper_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_ev_study   FOREIGN KEY (study_id)  REFERENCES study(study_id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE somatic (
  somatic_id        BIGINT PRIMARY KEY AUTO_INCREMENT,
  variant_id        BIGINT NOT NULL,
  status            ENUM('observed','likely_somatic','germline_conflict','unknown') NOT NULL DEFAULT 'observed',
  source_name       VARCHAR(32) NOT NULL DEFAULT '',      -- e.g., COSMIC
  UNIQUE KEY uq_somatic_variant_status_source (variant_id, status, source_name),
  KEY idx_somatic_variant (variant_id),
 
  CONSTRAINT fk_somatic_variant FOREIGN KEY (variant_id) REFERENCES variants(variant_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE variant_freq (
  variant_freq_id   BIGINT PRIMARY KEY AUTO_INCREMENT,
  variant_id        BIGINT NOT NULL,
  study_id          BIGINT NOT NULL,
  af                DECIMAL(6,5) NULL,    -- 0..1
  ac                INT NULL,
  an                INT NULL,
  UNIQUE (variant_id, study_id),
  KEY idx_vf_variant (variant_id),
  KEY idx_vf_study   (study_id),
  CONSTRAINT fk_vf_variant FOREIGN KEY (variant_id) REFERENCES variants(variant_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_vf_study   FOREIGN KEY (study_id)  REFERENCES study(study_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Optional per-sample and per-cell genotype tables (include only if needed now)

CREATE TABLE sample_variant_2 (         -- per-sample
  sample_variant2_id BIGINT PRIMARY KEY AUTO_INCREMENT,
  sample_id          BIGINT NOT NULL,
  variant_id         BIGINT NOT NULL,
  genotype           ENUM('0/0','0/1','1/1','./.') NULL,
  dp                 INT NULL,  -- depth
  gq                 INT NULL,  -- genotype quality
  UNIQUE (sample_id, variant_id),
  KEY idx_sv2_sample (sample_id),
  KEY idx_sv2_variant (variant_id),
  CONSTRAINT fk_sv2_sample  FOREIGN KEY (sample_id)  REFERENCES sample(sample_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_sv2_variant FOREIGN KEY (variant_id) REFERENCES variants(variant_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE sample_variant_1 (         -- per-cell
  sample_variant1_id BIGINT PRIMARY KEY AUTO_INCREMENT,
  cell_id            BIGINT NOT NULL,
  variant_id         BIGINT NOT NULL,
  genotype           ENUM('0/0','0/1','1/1','./.') NULL,
  dp                 INT NULL,
  UNIQUE (cell_id, variant_id),
  KEY idx_sv1_cell    (cell_id),
  KEY idx_sv1_variant (variant_id),
  CONSTRAINT fk_sv1_cell    FOREIGN KEY (cell_id)    REFERENCES cell(cell_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_sv1_variant FOREIGN KEY (variant_id) REFERENCES variants(variant_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
