# Data Ingestion Pipeline

## Purpose

This document describes how somatic variant data from published studies
is ingested into the Autoimmune Somatic Variant Database.

The pipeline is designed to ensure:
- traceability to the original publication
- reproducibility of database construction
- separation between raw literature data and curated database entities

This is a **literature-driven ingestion pipeline**, not a sequencing pipeline.


## Data Sources

Primary data sources include:
- peer-reviewed publications reporting somatic variants
- supplementary tables (PDF, Excel, CSV)
- manually curated variant lists from figures or text

The database does **not** ingest raw FASTQ/BAM/VCF files.


## Ingestion Stages

### Stage 1: Literature Extraction (Manual)

Variants are extracted from published studies and normalized into
structured tabular formats (CSV / TSV).

Typical extracted fields include:
- gene symbol
- reported genomic coordinates
- reference genome used in the paper
- variant description (HGVS or equivalent)
- disease context
- cell type or tissue context
- evidence notes from the publication

These files are **not committed** to version control if they are working drafts.


### Stage 2: Staging Tables

Extracted data is loaded into **staging tables** or staging CSVs.

Example:
- `sql/seeds/literature_driver_variants_v1.csv`

Staging data reflects the publication as closely as possible and may
contain:
- inconsistent naming
- mixed genome builds
- heterogeneous variant descriptions

No biological interpretation occurs at this stage.


### Stage 3: Normalization and Validation

Staged data is transformed into normalized relational tables using
SQL migration and seed scripts.

Key normalization steps include:
- mapping genes to canonical gene records
- resolving disease names into controlled vocabularies
- standardizing variant types and consequences
- preserving both paper-reported and lifted-over coordinates

Validation is performed via:
- schema constraints
- enum enforcement
- consistency checks in SQL migrations


### Stage 4: Provenance Preservation

Every variant record retains:
- study identifier
- publication metadata
- reference genome used in the paper
- original reported coordinates
- notes describing evidence and interpretation

This ensures all database entries remain auditable back to the source.


## Reproducibility

The entire ingestion process is reproducible by:
-  applying schema migrations in order (`sql/migrations/`)
-  loading seed files (`sql/seeds/`)
-  regenerating analysis views

No manual database edits are required after ingestion.


## What This Pipeline Does NOT Do

- perform variant calling
- realign sequencing data
- annotate variants using external tools (e.g. VEP)
- infer pathogenicity beyond what is reported in the literature

Those steps are explicitly out of scope.


## Related Documentation

- `01_schema_overview.md`
- `03_literature_curation.md`
- `04_analysis_views_and_queries.md`


