USE autoimmune_db;

ALTER TABLE disease_meta
  ADD COLUMN notes text NULL;
