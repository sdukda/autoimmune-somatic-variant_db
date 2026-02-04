# Study catalogue

This catalogue summarises which studies are currently curated in the database.

## Source of truth
- Curated study IDs and short names are included in:
  - `sql/seeds/literature_driver_variants_v1.csv` (columns: study_id, study_name_short)

Optional metadata (if populated):
- PMID/year/DOI may be stored in:
  - `study` table and/or `study_meta` table

## How to generate the catalogue (recommended)
### A) From the database (preferred)
Run:
```sql
SELECT
  ldv.study_id,
  MAX(ldv.study_name_short) AS study_name_short,
  sm.year,
  sm.pmid,
  sm.doi,
  COUNT(*) AS n_curated_rows,
  COUNT(DISTINCT ldv.gene_symbol) AS n_genes,
  COUNT(DISTINCT ldv.disease_name) AS n_diseases
FROM literature_driver_variants ldv
LEFT JOIN study_meta sm ON sm.study_id = ldv.study_id
GROUP BY ldv.study_id, sm.year, sm.pmid, sm.doi
ORDER BY ldv.study_id;
