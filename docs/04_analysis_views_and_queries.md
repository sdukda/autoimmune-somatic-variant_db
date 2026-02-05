# Analysis Views and Query Layer

## Purpose

This document describes the **analysis-facing SQL views and query layer**
used by the Autoimmune Somatic Variant Database.

These views sit **on top of the curated relational schema** and provide
stable, reproducible, and query-efficient access for:

- exploratory analysis
- summary statistics
- web UI pages (gene, disease, study, variant)
- downstream research workflows

The view layer deliberately separates:
- **raw curated entities** (tables)
- **analysis-ready representations** (views)

---

## Design Principles

The analysis layer follows these principles:

- **Read-only**: all views are derived; no data is modified
- **Reproducible**: views can be regenerated from migrations
- **Human-readable**: columns are named for interpretation, not storage
- **Stable contracts**: UI and analysis code depend on views, not base tables
- **Literature-centric**: every aggregation preserves provenance

---

## Core Flat Views

### `v_literature_variants_flat`

This is the **central analysis view** of the database.

It flattens variant-level information across:

- gene
- genomic coordinates
- consequence / impact
- disease context
- cell type context
- study metadata

**Key characteristics**
- one row per *(study × variant × disease × cell type)* context
- both paper-reported and lifted-over coordinates are retained
- noncoding and unknown consequences are explicitly supported

This view underpins:
- variant browsing
- downstream summary views
- ad hoc researcher queries

---

### `v_literature_variants_flat_celltype_v1`

An extension of the flat variant view with explicit
cell-type normalization and rollups.

Used for:
- disease–cell type analyses
- immune compartment–specific queries
- UI disease pages

---

## Summary and Rollup Views

### Gene-centric summaries

Examples:
- `v_literature_summary_by_gene`

Provides:
- number of unique variants per gene
- number of studies reporting the gene
- number of diseases associated with the gene

Used by:
- Gene page
- Gene ranking / prioritization queries

---

### Disease-centric summaries

Examples:
- `v_literature_summary_by_disease`
- `disease_rollup`

Provides:
- variant burden per disease
- gene diversity per disease
- study coverage

Used by:
- Disease page
- Cross-disease comparisons

---

### Variant-centric summaries

Examples:
- `v_literature_summary_by_variant`
- `v_literature_summary_by_variant_coords`

Provides:
- how often a variant appears across studies
- disease and cell-type diversity
- coordinate-based aggregation

Used by:
- Variant page
- Hotspot-style analyses

---

## Researcher-Oriented Views

### `v_variant_lookup`

A convenience view designed for:

- fast lookup by gene or coordinate
- downstream scripting
- export workflows

This view prioritizes:
- simplicity
- minimal joins
- predictable column names

---

## Query Usage Patterns

The views are designed to support:

- **gene → variants → diseases**
- **disease → genes → variants**
- **variant → studies → contexts**
- **cell type–specific filtering**

All UI queries use **views only**, never base tables.

This ensures:
- consistent behavior
- reduced query complexity
- insulation from schema evolution

---

## Relationship to UI Layer

The web interface (`ui/public/*.php`) relies exclusively on
the analysis views.

Benefits:
- UI logic remains simple
- schema changes are absorbed at the view level
- analysis and UI stay aligned

No UI code directly joins raw tables.

---

## Limitations and Scope

This analysis layer:

- does **not** perform statistical modeling
- does **not** infer causality
- does **not** replace variant callers or pipelines

It provides **structured, queryable evidence** suitable for
manual interpretation and downstream analysis.

---

## Related Documentation

- `01_schema_overview.md`
- `02_data_ingestion_pipeline.md`
- `03_data_validation_and_qc.md`
