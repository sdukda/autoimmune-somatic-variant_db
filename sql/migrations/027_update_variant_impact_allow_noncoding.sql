-- 027_update_variant_impact_allow_noncoding.sql
USE autoimmune_db;

-- Drop old CHECK (name must match exactly)
ALTER TABLE literature_driver_variants
DROP CHECK chk_ldv_variant_impact_atomic;

-- Recreate CHECK with Noncoding included
ALTER TABLE literature_driver_variants
ADD CONSTRAINT chk_ldv_variant_impact_atomic
CHECK (
  variant_impact IS NULL
  OR variant_impact IN (
    'Missense',
    'Nonsense',
    'Frameshift',
    'Splice',
    'Synonymous',
    'Inframe indel',
    'Noncoding'
  )
);
