# Data population (how curated data enters the DB)

This project is populated from curated CSVs + SQL seed scripts.

## Primary curated CSVs
### 1) literature_driver_variants_v1.csv
Path: `sql/seeds/literature_driver_variants_v1.csv`

Columns (header):
- study_id, study_name_short
- gene_symbol, protein_change, cDNA_HGVS
- paper_ref_genome_name, paper_chrom, paper_pos, paper_ref, paper_alt
- lifted_ref_genome_name, lifted_chrom, lifted_pos, lifted_ref, lifted_alt
- variant_type, is_driver
- disease_name, cell_type_name
- evidence_type, notes, remarks

### 2) autoimmune_somatic_mutation_celltype_annotation_v1.csv
Path: `sql/seeds/autoimmune_somatic_mutation_celltype_annotation_v1.csv`
Used to map diseases ↔ cell types (and ontology IDs where available).

### 3) literature_variant_consequence_ucsc_v1.csv
Path: `sql/seeds/literature_variant_consequence_ucsc_v1.csv`
Used to backfill/normalize consequence categories for variants (UCSC-derived).

## Seed scripts (current set)
Core lookups:
- `sql/seeds/001_seed_core_lookups.sql`

Disease/cell type/study metadata:
- `009_disease_meta.seed.sql` + `010_apply_disease_meta.sql`
- `014_cell_type_meta.seed.sql` + `015_apply_cell_type_meta.sql`
- `017_study_meta.seed.sql` + `018_apply_study_meta.sql` + `019_study_meta_updates.sql`

LDV loading:
- `010_seed_literature_driver_variants_v1.sql`
- mapping/backfills:
  - `013_backfill_literature_variant_study.sql`
  - `014_backfill_cell_type_from_literature.sql`
  - `022_seed_literature_driver_variants_mapped.sql`

Disease–cell type mapping:
- staging loader:
  - `021_stage_disease_celltype_from_csv.sql`

Consequence staging/backfills:
- migrations 035–049 (staging table + backfill + enum + view updates)

## Reproducible local load (recommended order)
1) Create database
2) Apply base schema (001)
3) Apply view/normalization migrations needed by UI
4) Load core lookups (001_seed_core_lookups.sql)
5) Load disease/cell_type/study metadata
6) Load LDV CSV + mapping scripts
7) Run consequence staging/backfills if needed

## Verification queries
- How many curated rows exist?
  - `SELECT COUNT(*) FROM literature_driver_variants;`
- How many studies appear in curated LDV?
  - `SELECT study_id, COUNT(*) AS n_rows FROM literature_driver_variants GROUP BY study_id ORDER BY n_rows DESC;`
- Flat view exists?
  - `SELECT COUNT(*) FROM v_literature_variants_flat;`
