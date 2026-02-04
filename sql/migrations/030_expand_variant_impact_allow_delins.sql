-- 030_expand_variant_impact_allow_delins.sql
-- Save in sql/migrations/
-- Run: mysql -u root -p autoimmune_db < 029_expand_variant_impact_allow_delins.sql

ALTER TABLE literature_driver_variants
DROP CHECK chk_ldv_variant_impact_atomic;

ALTER TABLE literature_driver_variants
ADD CONSTRAINT chk_ldv_variant_impact_atomic
CHECK (
  variant_impact IS NULL
  OR variant_impact IN (
    'Missense','Nonsense','Frameshift','Splice','Synonymous',
    'Inframe indel','Noncoding',
    'Frameshift delins','Inframe delins'
  )
);
