-- 028_normalise_variant_impact_values.sql
USE autoimmune_db;

-- INTRON → Noncoding
UPDATE literature_driver_variants
SET variant_impact = 'Noncoding'
WHERE variant_impact = 'INTRON';

-- no-SNV → Noncoding (because you now know these are noncoding)
UPDATE literature_driver_variants
SET variant_impact = 'Noncoding'
WHERE variant_impact = 'no-SNV';

-- These are NOT consequences → NULL
UPDATE literature_driver_variants
SET variant_impact = NULL
WHERE variant_impact IN ('Deletion', 'SNV');

-- START_LOST → Nonsense (LoF)
UPDATE literature_driver_variants
SET variant_impact = 'Nonsense'
WHERE variant_impact = 'START_LOST';
