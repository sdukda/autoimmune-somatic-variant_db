USE autoimmune_db;

-- 1) Add Impact column to base table
ALTER TABLE literature_driver_variants
  ADD COLUMN variant_impact VARCHAR(64) NULL AFTER variant_type;

-- 2) Backfill Impact from existing variant_type
UPDATE literature_driver_variants
SET variant_impact =
  CASE
    WHEN variant_type LIKE '%Missense%' THEN 'Missense'
    WHEN variant_type LIKE '%Nonsense%' OR variant_type LIKE '%Stop%' THEN 'Nonsense'
    WHEN variant_type LIKE '%Frameshift%' THEN 'Frameshift'
    WHEN variant_type LIKE '%Splice%' THEN 'Splice'
    WHEN variant_type LIKE '%Inframe%' THEN 'Inframe'
    WHEN variant_type LIKE '%Deletion%' THEN 'Deletion'
    WHEN variant_type LIKE '%Insertion%' THEN 'Insertion'
    WHEN variant_type LIKE '%Indel%' THEN 'Indel'
    WHEN variant_type LIKE '%CNV%' OR variant_type LIKE '%Copy%' THEN 'CNV'
    ELSE NULL
  END
WHERE variant_impact IS NULL OR variant_impact = '';

-- 3) Recreate the view with the new Impact column included
CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER=`root`@`localhost`
SQL SECURITY DEFINER
VIEW `v_literature_variants_flat` AS
select
  `ldv`.`literature_variant_id` AS `literature_variant_id`,
  `ldv`.`study_id` AS `study_id`,
  `s`.`study_name` AS `study_name`,
  `ldv`.`study_name_short` AS `study_name_short`,
  `ldv`.`gene_symbol` AS `gene_symbol`,
  `ldv`.`cDNA_HGVS` AS `cDNA_HGVS`,
  `ldv`.`protein_change` AS `protein_change`,
  `ldv`.`variant_type` AS `variant_type`,

  `ldv`.`variant_impact` AS `impact`,   -- NEW

  `ldv`.`is_driver` AS `is_driver`,
  `d`.`disease_id` AS `disease_id`,
  `d`.`disease_name` AS `disease_name`,
  `d`.`category` AS `disease_category`,
  `d`.`disease_ontology_id` AS `disease_ontology_id`,
  `ldv`.`cell_type_name` AS `cell_type_name`,
  `ct`.`cell_type_ontology_id` AS `cell_type_ontology_id`,
  `ldv`.`evidence_type` AS `evidence_type`,
  `ldv`.`notes` AS `notes`,
  `ldv`.`Remarks` AS `Remarks`,
  `rgp`.`ref_genome_name` AS `paper_ref_genome`,
  `ldv`.`paper_chrom` AS `paper_chrom`,
  `ldv`.`paper_pos` AS `paper_pos`,
  `ldv`.`paper_ref` AS `paper_ref`,
  `ldv`.`paper_alt` AS `paper_alt`,
  `rgl`.`ref_genome_name` AS `lifted_ref_genome`,
  `ldv`.`lifted_chrom` AS `lifted_chrom`,
  `ldv`.`lifted_pos` AS `lifted_pos`,
  `ldv`.`lifted_ref` AS `lifted_ref`,
  `ldv`.`lifted_alt` AS `lifted_alt`
from
  (((((`literature_driver_variants` `ldv`
  join `study` `s` on((`s`.`study_id` = `ldv`.`study_id`)))
  join `disease` `d` on((`d`.`disease_id` = `ldv`.`disease_id`)))
  left join `cell_type` `ct` on((`ct`.`cell_type_name` = `ldv`.`cell_type_name`)))
  left join `reference_genome` `rgp` on((`rgp`.`ref_genome_id` = `ldv`.`paper_ref_genome_id`)))
  left join `reference_genome` `rgl` on((`rgl`.`ref_genome_id` = `ldv`.`lifted_ref_genome_id`)));
