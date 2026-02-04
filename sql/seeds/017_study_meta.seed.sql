USE autoimmune_db;

CREATE TABLE IF NOT EXISTS study_meta (
  study_id   BIGINT NOT NULL,
  year       INT NULL,
  pmid       VARCHAR(16) NULL,
  doi        VARCHAR(128) NULL,
  notes      TEXT NULL,
  PRIMARY KEY (study_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Fill these rows as you curate (example placeholders)
INSERT INTO study_meta (study_id, year, pmid, doi, notes) VALUES
  (1, NULL, NULL, NULL, NULL),
  (2, NULL, NULL, NULL, NULL),
  (3, NULL, NULL, NULL, NULL)
ON DUPLICATE KEY UPDATE
  year  = VALUES(year),
  pmid  = VALUES(pmid),
  doi   = VALUES(doi),
  notes = VALUES(notes);
