USE autoimmune_db;

DROP TABLE IF EXISTS stg_disease_celltype_csv;

CREATE TABLE stg_disease_celltype_csv (
  study_id               BIGINT NULL,
  study_name_short       VARCHAR(255) NULL,
  disease_name           VARCHAR(255) NULL,
  disease_ontology_id    VARCHAR(32)  NULL,
  cell_type              VARCHAR(255) NULL,
  cell_type_ontology_id  VARCHAR(32)  NULL,
  cell_type_notes        TEXT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Load your CSV (adjust the path if your CSV is elsewhere)
-- IMPORTANT: the CSV must have a header row:
-- study_id,study_name_short,disease_name,disease_ontology_id,cell_type,cell_type_ontology_id,cell_type_notes

LOAD DATA LOCAL INFILE '/Users/jc951016/Documents/autoimmune_db/sql/seeds/autoimmune_somatic_mutation_celltype_annotation_v1.csv'
INTO TABLE stg_disease_celltype_csv
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(study_id, study_name_short, disease_name, disease_ontology_id, cell_type, cell_type_ontology_id, cell_type_notes);

-- Quick sanity check
SELECT disease_name, disease_ontology_id, COUNT(*) AS n
FROM stg_disease_celltype_csv
GROUP BY disease_name, disease_ontology_id
ORDER BY n DESC;
