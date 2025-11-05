USE autoimmune_db;

INSERT INTO impact_severity (severity_level, severity_rank) VALUES
  ('UNKNOWN',0),
  ('LOW',1), 
  ('MODERATE',2), 
  ('HIGH',3)
ON DUPLICATE KEY UPDATE
    severity_rank = VALUES(severity_rank);
