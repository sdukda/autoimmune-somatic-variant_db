USE autoimmune_db;

-- Apply curated cell-type ontology IDs (CL) into main cell_type table
UPDATE cell_type c
JOIN cell_type_meta m
  ON m.cell_type_name = c.cell_type_name
SET
  c.cell_type_ontology_id = COALESCE(c.cell_type_ontology_id, m.cell_type_ontology_id),
  c.notes                 = COALESCE(c.notes, m.notes);
