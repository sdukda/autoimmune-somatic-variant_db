INSERT IGNORE INTO disease_rollup (parent_disease_id, child_disease_id)
VALUES
  (31, 7),   -- Vasculitis -> Mixed cryoglobulinemic vasculitis
  (30, 9);   -- Celiac disease -> Refractory celiac disease
