-- 025_normalize_variant_impact_to_consequence_buckets.sql
USE autoimmune_db;

UPDATE literature_driver_variants
SET variant_impact = CASE
  WHEN variant_impact IS NULL OR TRIM(variant_impact) = '' THEN NULL

  WHEN LOWER(variant_impact) LIKE '%frameshift%' THEN 'Frameshift'

  WHEN LOWER(variant_impact) LIKE '%inframe%' THEN 'Inframe indel'

  WHEN LOWER(variant_impact) LIKE '%missense%' THEN 'Missense'

  WHEN LOWER(variant_impact) LIKE '%nonsense%'
    OR LOWER(variant_impact) LIKE '%stop_gained%'
    OR LOWER(variant_impact) LIKE '%stop-gained%'
    OR LOWER(variant_impact) LIKE '%stopgain%'
    OR LOWER(variant_impact) LIKE '%stop%' THEN 'Nonsense'

  WHEN LOWER(variant_impact) LIKE '%splice%' THEN 'Splice'

  WHEN LOWER(variant_impact) LIKE '%synonymous%' THEN 'Synonymous'

  ELSE variant_impact
END;
