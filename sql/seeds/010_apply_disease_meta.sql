USE autoimmune_db;

UPDATE disease d
JOIN disease_meta m
  ON m.disease_name = d.disease_name
SET
  d.category = COALESCE(d.category, m.category),
  d.disease_ontology_id = COALESCE(d.disease_ontology_id, m.disease_ontology_id),
  d.notes = COALESCE(d.notes, m.notes);
