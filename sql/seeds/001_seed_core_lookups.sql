-- 001_seed_core_lookups.sql
-- Controlled vocabulary seeds (canonical)

-- reference_genome
INSERT INTO reference_genome (ref_genome_name)
VALUES
  ('GRCh37'),
  ('GRCh38'),
  ('Not specified')
ON DUPLICATE KEY UPDATE
  ref_genome_name = VALUES(ref_genome_name);

-- disease (canonical names only)
INSERT INTO disease (disease_name)
VALUES
  ('Adult-onset autoinflammatory syndrome'),
  ('Autoimmune lymphoproliferative syndrome'),
  ('Chronic liver disease'),
  ('Felty syndrome'),
  ('Inflammatory bowel disease'),
  ('Ulcerative colitis'),
  ('Mixed cryoglobulinemic vasculitis'),
  ('Primary cold agglutinin disease'),
  ('Refractory celiac disease'),
  ('Multiple sclerosis'),
  ('Rheumatoid arthritis'),
  ('Systemic lupus erythematosus'),
  ('Takayasu arteritis'),
  ('VEXAS syndrome')
ON DUPLICATE KEY UPDATE
  disease_name = VALUES(disease_name);
