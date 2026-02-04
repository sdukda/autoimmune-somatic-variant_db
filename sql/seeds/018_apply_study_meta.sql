USE autoimmune_db;

UPDATE study s
JOIN study_meta m
  ON m.study_id = s.study_id
SET
  s.year  = COALESCE(s.year, m.year),
  s.pmid  = COALESCE(s.pmid, m.pmid),
  s.doi   = COALESCE(s.doi, m.doi),
  s.notes = COALESCE(s.notes, m.notes);
