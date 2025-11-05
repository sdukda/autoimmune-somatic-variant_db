-- === LOOKUPS ===
USE autoimmune_db;

CREATE TABLE reference_genome (
  ref_genome_id     INT PRIMARY KEY AUTO_INCREMENT,
  assembly_name     VARCHAR(32) NOT NULL,-- e.g., 'GRCh38' or 'GRCh37'
  version           VARCHAR(16) NULL,   -- e.g., 'p14' (NULL for no patch)
  build_date        DATE NULL, 
  Note              TEXT NULL,
  UNIQUE(assembly_name, version)  -- ensures each combo appears once
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;;

CREATE TABLE variant_type (
  variant_type_id   INT PRIMARY KEY AUTO_INCREMENT,
  code              VARCHAR(16) NOT NULL,
  label             VARCHAR(64) NOT NULL,
  UNIQUE (code),
  UNIQUE (label)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;;

CREATE TABLE impact_severity (
  impact_severity_id  INT PRIMARY KEY AUTO_INCREMENT,
  severity_level      VARCHAR(16) NOT NULL,     -- LOW/MODERATE/HIGH/UNKNOWN
  severity_rank       TINYINT NOT NULL,         -- 0..3
  UNIQUE (severity_level)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;;

CREATE TABLE variant_impact (
  impact_id         INT PRIMARY KEY AUTO_INCREMENT,
  consequence       VARCHAR(64) NOT NULL,       -- e.g., missense_variant
  display_name      VARCHAR(64) NOT NULL,       -- e.g., Missense
  UNIQUE (consequence)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE technology (
  technology_id     INT PRIMARY KEY AUTO_INCREMENT,
  platform          VARCHAR(32) NOT NULL,       -- WES/WGS/10x_scRNA/Smart-seq2/...
  UNIQUE (platform)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
