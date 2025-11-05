USE autoimmune_db;
INSERT INTO variant_impact (consequence, display_name) VALUES
  ('missense_variant','Missense'),
  ('synonymous_variant','Synonymous'),
  ('stop_gained','Stop gained'),
  ('frameshift_variant','Frameshift')
ON DUPLICATE KEY UPDATE
    display_name = VALUES(display_name);
