# Data Validation and Quality Control
## Purpose
This document describes how literature-derived somatic variant data is
validated and quality-controlled before being exposed through the
Autoimmune Somatic Variant Database.
The validation process is designed to ensure:
-	internal consistency of curated data
-	traceability to original publications
-	reproducibility of database construction
	safe downstream querying and aggregation
This is not experimental QC and not sequencing QC.
It operates exclusively on curated, literature-derived data.

## Scope
Validation applies to:
-	literature-curated somatic variants
-	disease and cell-type annotations
-	genomic coordinates and reference genome metadata
-	derived analysis and summary views
Out of scope:
-	raw sequencing data
-	alignment or variant calling
-	experimental quality metrics

## Validation principles
The validation layer follows four guiding principles:
-	Do not overwrite published data
-	Make uncertainty explicit
-	Normalize where possible
-	Preserve full auditability

## Validation stages
## 1. Schema-level validation
All incoming data must conform to the relational schema defined in:
-	sql/migrations/001_create_all_tables.sql
-	subsequent migrations in sql/migrations/
Validation is enforced using:
-	primary keys
-	foreign keys
-	NOT NULL constraints
-	ENUM / controlled-value columns
-	explicit data types
This ensures structural correctness before any downstream logic is applied.

## 2. Controlled vocabulary normalization
Several fields are normalized to ensure cross-study comparability.
| Field                     | Validation / Normalization |
|---------------------------|----------------------------|
| variant_type              | SNV, indel, frameshift, delins, noncoding |
| variant_impact / consequence | Mapped to controlled consequence buckets |
| reference_genome          | GRCh37 or GRCh38 |
| disease_name              | Curated disease metadata |
| cell_type_name            | Curated cell-type metadata |

Normalization is implemented using:
-	staging tables
-	backfill migrations
-	deterministic update scripts
Original literature values are preserved where relevant.

## 3. Genomic coordinate validation
Each variant record may include:
-	paper-reported genomic coordinates
-	lifted coordinates (GRCh37 ↔ GRCh38)
Validation checks include:
-	chromosome naming consistency (chr1 vs 1)
-	valid reference and alternate allele formats
-	plausible genomic positions
-	explicit tracking of reference genome source
Lifted coordinates are stored separately and never overwrite
paper-reported coordinates.

## 4. Consequence validation
Variant consequences are validated using:
-	controlled ENUM values
-	explicit handling of noncoding variants
-	explicit handling of unknown or ambiguous consequences
This prevents silent misclassification and makes uncertainty visible
to downstream users.

## 5. Duplicate and consistency checks
The schema allows:
-	the same variant to appear in multiple studies
-	multiple disease or cell-type associations per variant
Validation ensures:
-	no duplicate variant entries within the same study
-	unique variant–study relationships
-	consistent roll-up counts in summary views
These checks are enforced via:
-	composite keys
-	integrity checks in migrations
-	deterministic view definitions

## 6. Reproducibility and auditability
All validation logic is implemented as:
-	version-controlled SQL migrations
-	seed files
-	deterministic backfill scripts
No manual edits are applied to production tables.
The entire database can be rebuilt from scratch using:
-	schema migrations
-	seed data
-	validation and normalization scripts

## Known limitations
-	Validation depends on accuracy and completeness of published reports
-	Some studies report incomplete coordinates or transcript context
-	External annotation sources may evolve over time
Such cases are handled explicitly using:
-	Unknown / NA values
-	curator notes and remarks

## Relationship to other documentation
-	Schema overview: 01_schema_overview.md
-	Data ingestion: 02_data_ingestion_pipeline.md
-	Analysis views: 04_analysis_views_and_queries.md
-	Curation rules: 05_curation_rules_and_decisions.md

## Summary
The validation and QC layer ensures that literature-derived somatic variant
data is consistent, auditable, and safe for downstream analysis, while
preserving the original context and limitations of each study.


