## Applying the schema
Base schema:
- `sql/migrations/001_create_all_tables.sql`

Views and later changes:
- subsequent numbered files in `sql/migrations/` (views + normalization)

## Design notes
- Variants are represented at the literature-report level (study + disease + cell type context)
- The dataset preserves both:
  - paper-reported coordinates (as in the publication)
  - lifted-over coordinates (for cross-study comparison)
- UI pages rely on rollup and “flat” views (e.g. `v_literature_variants_flat*`, summary-by-gene/disease/variant views)

## ERD
See:
- `docs/erd/ERD_AID - high_level.pdf`
- `docs/erd/ERD_AID - detailed.pdf`
