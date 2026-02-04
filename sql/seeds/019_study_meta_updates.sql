USE autoimmune_db;

-- 019_study_meta_updates.sql
-- Purpose:
-- 1) Ensure a study_meta table exists to hold curated metadata (year/pmid/doi)
-- 2) Insert/update curated metadata rows safely (re-runnable)
-- 3) Apply onto the main study table (fills only missing values)

-- 1) Create a small metadata table
CREATE TABLE IF NOT EXISTS study_meta (
  study_id BIGINT NOT NULL,
  year     INT NULL,
  pmid     VARCHAR(16) NULL,
  doi      VARCHAR(128) NULL,
  notes    TEXT NULL,
  PRIMARY KEY (study_id),
  CONSTRAINT fk_study_meta_study
    FOREIGN KEY (study_id) REFERENCES study(study_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2) Insert / update curated mappings here
-- Leave NULL for unknown fields
-- Fill gradually as you curate
INSERT INTO study_meta (study_id, year, pmid, doi, notes) VALUES
  (1, 2025, '40367192', '10.1126/scitranslmed.adp6812', 'Refractory Celiac Disease'), 
(2, 2025, '39818208', '10.1016/j.immuni.2024.12.011', 'hepatitis-C–associated cryoglobulinemic vasculitis'),
(3, 2024, '37084382', '10.1182/blood-2024-204334', 'VEXAS syndrome'), 
(4, 2024, '39497832', '10.3389/fimmu.2024.1466276', 'Rheumatoid arthritis'),
(5, 2022, '35361277', '10.1186/s41232-022-00195-w', 'Systemic lupus erythematosus'),
(6, 2020, '32697969', '10.1016/j.cell.2020.06.036', 'Inflammatory Bowel Disease'),
(7, 2020, '32059783', '10.1016/j.cell.2020.01.029', 'Mixed cryoglobulinemic vasculitis'),
(8, 2020, '33108101', '10.1056/NEJMoa2026834', 'Adult-onset autoinflammatory syndrome'), 
(9, 2019, '31853059', '10.1038/s41586-019-1844-5', 'Ulcerative colitis'),
(10, 2019, '30955891', '10.1016/j.cell.2019.03.026', 'Chronic liver disease with cirrhosis'),
(11, 2018, '30061683', '10.1038/s41408-018-0107-2', 'Rheumatoid arthritis'),
(12, 2018, '38049983', '10.1136/ard-2023-224933', 'Takayasu’s arteritis, ANCA associated vasculitis+Giant cell arteritis'),
(13, 2018, '29265349', '10.1111/bjh.15063', 'Primary cold agglutinin disease'),
(14, 2018, '29217783', '10.3324/haematol.2017.175729', 'Compares FS to large granular lymphocyte leukemia'),
(15, 2017, '28635960', '10.1038/ncomms15869', 'Rheumatoid arthritis'),
(16, 2017, '27932211', '10.1016/j.clim.2016.11.018', 'Relapsing multiple sclerosis + Myasthenia gravis+Narcolepsy'),
(17, 2011, '21063026', '10.1182/blood-2010-08-301515', 'Autoimmune lymphoproliferative syndrome')



ON DUPLICATE KEY UPDATE
  year  = VALUES(year),
  pmid  = VALUES(pmid),
  doi   = VALUES(doi),
  notes = VALUES(notes);

-- 3) Apply onto main study table (fill only missing values)
UPDATE study s
JOIN study_meta m ON m.study_id = s.study_id
SET
  s.year = COALESCE(s.year, m.year),
  s.pmid = COALESCE(s.pmid, m.pmid),
  s.doi  = COALESCE(s.doi,  m.doi)
;
