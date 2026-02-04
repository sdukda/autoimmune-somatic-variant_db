-- 026_fix_illegal_variant_impact_values.sql
USE autoimmune_db;

-- 1) no-SNV is not a consequence -> unknown (NULL)
UPDATE literature_driver_variants
SET variant_impact = NULL
WHERE variant_impact = 'no-SNV';

-- 2) INTRON is noncoding, not in allowed list -> unknown (NULL)
UPDATE literature_driver_variants
SET variant_impact = NULL
WHERE variant_impact = 'INTRON';

-- 3) These are variant *types*, not consequences -> unknown (NULL)
UPDATE literature_driver_variants
SET variant_impact = NULL
WHERE variant_impact IN ('Deletion', 'SNV');

-- 4) START_LOST -> bucket as Nonsense (LoF)
UPDATE literature_driver_variants
SET variant_impact = 'Nonsense'
WHERE variant_impact = 'START_LOST';
