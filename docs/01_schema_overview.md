# Schema Overview

## Project context

This project implements a relational MySQL schema for curating and analysing
**somatic variants reported in autoimmune and inflammatory diseases**.

The schema is designed to:
- integrate variants reported across heterogeneous studies
- preserve *paper-reported coordinates* alongside *lifted-over coordinates*
- explicitly capture disease, cell type, and evidence context
- support downstream researcher-facing queries (gene-, disease-, and variant-centric)

The database is **not a raw sequencing store**.  
It is a *curated literature knowledge base* focused on somatic variation.


## Design principles

The schema follows five core principles:

1. **Variants are the central entity**  
   All analytical views ultimately aggregate around genomic variants.

2. **Paper provenance is preserved**  
   Each variant retains the reference genome, coordinates, and notation
   exactly as reported in the original publication.

3. **Normalization where it adds clarity, denormalization where it adds usability**  
   Core entities are normalized; analysis-ready views are intentionally flattened.

4. **Support for non-coding and ambiguous consequences**  
   The schema does not assume all variants map cleanly to coding consequences.

5. **Reproducible evolution**  
   All schema changes are applied via versioned SQL migrations.

## Core tables

### `study`
Represents a published research study.

- One row per publication
- Identified internally by `study_id`
- Linked to metadata (PMID, DOI, year) via `study_meta`

Purpose:
-  Anchor all variants to their source publication.


### `literature_driver_variants`
The central curation table.

Each row represents:
-  A *single somatic variant* reported in a study, in a specific disease and cell-type context.

Key features:
- stores **paper-reported genome build and coordinates**
- stores **lifted-over coordinates** (GRCh37 / GRCh38)
- captures variant type, driver classification, disease, cell type, and evidence notes

This table intentionally retains some redundancy to preserve scientific context.


### `literature_variant_study`
Associative table linking variants to studies.

Purpose:
- allows a single variant to be referenced by multiple studies
- supports cross-study aggregation and summaries

### Reference / lookup tables

The schema includes normalized lookup tables for:
- diseases
- cell types
- genes
- variant impact categories
- consequence enums

These ensure consistency across curated data while allowing controlled extension.


## Analysis-ready views

To support efficient querying and UI access, the schema defines multiple
**flattened SQL views**, including:

- `v_literature_variants_flat`
- `v_literature_variants_flat_celltype`
- `v_literature_summary_by_gene`
- `v_literature_summary_by_disease`
- `v_literature_summary_by_variant`

These views:
- combine variant, study, disease, and cell-type context
- standardize consequence and impact labels
- are regenerated via migrations, not manual edits

Views are treated as *derived artifacts*, not primary data.


## Handling reference genomes

The schema explicitly distinguishes:

- **paper-reported coordinates**  
  As published by the study authors

- **lifted-over coordinates**  
  Generated computationally to support cross-study comparison

This avoids ambiguity and preserves traceability.

No coordinate overwriting occurs.


## Migration strategy

All schema changes are applied through ordered SQL migration files located in:

## Schema Definition and Migrations

The database schema is defined and evolved using versioned SQL migration files
located in the `sql/migrations/` directory.

### sql/migrations/

Key properties:
- idempotent where possible
- chronologically ordered
- auditable and reproducible

Archived or superseded migrations are retained for historical reference.


## Intended usage

This schema is designed to support:
- literature-driven somatic variant research
- autoimmune disease genomics
- clonal hematopoiesis–related analyses
- downstream visualization and query interfaces

It is **not intended** to replace raw sequencing pipelines or variant callers.


## Related documentation

- `02_data_ingestion_pipeline.md`
- `03_literature_curation.md`
- `04_analysis_views_and_queries.md`
