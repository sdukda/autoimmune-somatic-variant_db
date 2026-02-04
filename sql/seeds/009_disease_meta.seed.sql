USE autoimmune_db;

CREATE TABLE IF NOT EXISTS disease_meta (
  disease_name         varchar(128) NOT NULL,
  category             varchar(32)  NULL,
  disease_ontology_id  varchar(32)  NULL,
  notes                text         NULL,
  PRIMARY KEY (disease_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO disease_meta (disease_name, category, disease_ontology_id, notes) VALUES
  ('Adult-onset autoinflammatory syndrome',   'autoinflammatory', NULL, NULL),
  ('Autoimmune lymphoproliferative syndrome', 'immune dysregulation', NULL, NULL),
  ('Chronic liver disease',                   'other', NULL, NULL),
  ('Felty syndrome',                          'autoimmune', NULL, NULL),
  ('Inflammatory bowel disease',              'autoimmune', NULL, NULL),

  ('Mixed cryoglobulinemic vasculitis',       'autoimmune', 'DOID:2917', NULL),
  ('Multiple sclerosis',                      'autoimmune', NULL, NULL),
  ('Primary cold agglutinin disease',         'other', NULL, NULL),
  ('Refractory celiac disease',               'autoimmune', NULL, NULL),
  ('Rheumatoid arthritis',                    'autoimmune', NULL, NULL),
  ('Systemic lupus erythematosus',            'autoimmune', NULL, NULL),
  ('Takayasu arteritis',                      'autoimmune', NULL, NULL),
  ('Ulcerative colitis',                      'autoimmune', NULL, NULL),
  ('VEXAS syndrome',                          'autoinflammatory', NULL, NULL)
ON DUPLICATE KEY UPDATE
  category            = VALUES(category),
  disease_ontology_id = VALUES(disease_ontology_id),
  notes               = VALUES(notes);
