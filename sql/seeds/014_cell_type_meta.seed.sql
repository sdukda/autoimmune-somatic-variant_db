USE autoimmune_db;

INSERT INTO cell_type_meta (cell_type_name, cell_type_ontology_id, notes)
VALUES
  ('Hepatocyte', 'CL:0000182', 'Hepatocyte'),
  ('CD14+ monocytes', 'CL:0000576', 'Monocyte (CD14+)'),
  ('CD8+ T cell (peripheral blood)', 'CL:0000625', 'CD8-positive, alpha-beta T cell'),
  ('hematopoietic cell', 'CL:0000988', 'Hematopoietic cell'),
  ('Hematopoietic stem and progenitor cells', 'CL:0000034', 'Hematopoietic stem cell / progenitor'),
  ('Colonic epithelial cells', 'CL:0000066', 'Epithelial cell (colon)'),
  ('Colonic epithelial crypts', 'CL:0000066', 'Epithelial cell (crypt compartment)'),
  ('IgM+ memory B cell', 'CL:0000787', 'Memory B cell (IgM+)'),
  ('Innate lymphoid cell', 'CL:0001065', 'Innate lymphoid cell')
ON DUPLICATE KEY UPDATE
  cell_type_ontology_id = VALUES(cell_type_ontology_id),
  notes = VALUES(notes);
