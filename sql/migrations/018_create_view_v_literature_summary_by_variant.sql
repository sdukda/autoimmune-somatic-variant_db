CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER=`root`@`localhost`
SQL SECURITY DEFINER
VIEW v_literature_summary_by_variant AS
SELECT
  ldv.gene_symbol,
  ldv.cDNA_HGVS,
  ldv.protein_change,

  COUNT(*)                            AS n_reports,
  COUNT(DISTINCT ldv.study_id)        AS n_studies,

  GROUP_CONCAT(
    DISTINCT ldv.study_name_short
    ORDER BY ldv.study_name_short
    SEPARATOR '; '
  )                                   AS studies

FROM literature_driver_variants ldv

GROUP BY
  ldv.gene_symbol,
  ldv.cDNA_HGVS,
  ldv.protein_change;
