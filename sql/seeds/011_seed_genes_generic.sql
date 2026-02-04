-- 011_seed_genes_generic.sql
-- Template: seed ONLY the genes needed for a given paper (do NOT try to pre-load ~20k genes).
-- Replace the VALUES rows with your paper's gene symbols.
-- Assumes reference_genome has already been seeded (e.g., GRCh37 / GRCh38).

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS=0;

-- Choose the reference genome for these genes:
-- Example: SET @rg := 'GRCh38';
SET @rg := 'GRCh38';

-- Insert genes (safe to re-run; uses the uq_gene_symbol_ref constraint)
INSERT INTO genes (ref_genome_id, gene_symbol)
SELECT rg.ref_genome_id, v.gene_symbol
FROM reference_genome rg
JOIN (
  SELECT 'DNMT3A' AS gene_symbol
  UNION ALL SELECT 'TET2'
  -- UNION ALL SELECT 'ASXL1'
  -- UNION ALL SELECT 'PPM1D'
) v
WHERE rg.ref_genome_name = @rg
ON DUPLICATE KEY UPDATE gene_id = gene_id;

SET FOREIGN_KEY_CHECKS=1;

