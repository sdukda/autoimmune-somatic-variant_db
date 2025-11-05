-- 002_alter_schema_2025_11.sql
-- Nov 2025 adjustments for autoimmune_db
-- Based on current constraints/indexes you listed.

-- ===== 1) sample_variant_call: drop 3 columns =====
-- (No indexes/constraints on these columns per your inventory.)
ALTER TABLE sample_variant_summary
  ADD COLUMN qc_status VARCHAR(32) NULL,
    ADD COLUMN somatic_source VARCHAR(32) NULL;

    -- ===== 4) variant_annotation: rename PK ann_id -> annotation_id; add impact =====
    -- Your inventory shows no child FKs to ann_id; rename is safe and PRIMARY remains.
    ALTER TABLE variant_annotation
      RENAME COLUMN ann_id TO annotation_id;

      ALTER TABLE variant_annotation
        ADD COLUMN impact VARCHAR(32) NULL;

        -- ===== 5) variant_freq: drop columns that are part of a UNIQUE =====
        -- The unique uq_vf_variant_cohort_pop = (variant_id, cohort_name, population_code)
        -- must be dropped before dropping population_code.
        ALTER TABLE variant_freq
          DROP INDEX uq_vf_variant_cohort_pop;

          ALTER TABLE variant_freq
            DROP COLUMN population_code,
              DROP COLUMN source_version;

              -- Optional: replace the unique with a new business rule if desired.
              -- Common choice: (variant_id, cohort_name) must be unique.
              -- Uncomment if that rule matches your ER decisions.
              -- ALTER TABLE variant_freq
              --   ADD UNIQUE KEY uq_vf_variant_cohort (variant_id, cohort_name);

              -- ===== 6) variants: drop ref_alt_hash that is part of a UNIQUE =====
              -- Current unique uq_variant_build_pos_hash = (ref_genome_id, chrom, pos, ref_alt_hash)
              -- Drop the unique first, then the column.
              ALTER TABLE variants
                DROP INDEX uq_variant_build_pos_hash;

                ALTER TABLE variants
                  DROP COLUMN ref_alt_hash;

                  -- Optional: if your table has (ref, alt) columns, you can preserve
                  -- dedup semantics by making (ref_genome_id, chrom, pos, ref, alt) uni-- 002_alter_schema_2025_11.sql
-- Nov 2025 adjustments for autoimmune_db
-- Based on current constraints/indexes you listed.

-- ===== 1) sample_variant_call: drop 3 columns =====
-- (No indexes/constraints on these columns per your inventory.)
ALTER TABLE sample_variant_call
  DROP COLUMN caller_name,
  DROP COLUMN call_date,
  DROP COLUMN filters;

-- ===== 2) patient: rename age_years -> age =====
-- (No FK/unique on age_years per your inventory; rename is safe.)
ALTER TABLE patient
  RENAME COLUMN age_years TO age;

-- Optional (keep commented if not needed):
-- ALTER TABLE patient ADD CONSTRAINT chk_patient_age CHECK (age IS NULL OR age BETWEEN 0 AND 150);

-- ===== 3) sample_variant_summary: add qc_status, somatic_source =====
-- (Adds are nullaque:
-- Uncomment if present in your schema and you want that rule.
-- ALTER TABLE variants
--   ADD UNIQUE KEY uq_variant_build_pos_ref_alt (ref_genome_id, chrom, pos, ref, alt);

-- NOTE:
-- - No FK names needed to drop because none referenced the changed columns.
-- - Existing FKs in your dump (e.g., fk_svc_variant, fk_svsum_variant, fk_va_variant, etc.)
--   are unaffected because their columns remain unchanged.
    -> FROM information_schema.KEY_COLUMN_USAGE
    -> WHERE table_schema = DATABASE()
    ->   AND table_name IN ('sample_variant_call','patient','sample_variant_summary',
    ->                      'variant_annotation','variant_freq','variants');
+------------------------+---------------------------+------------------------------+-----------------------+--------------------------+
| TABLE_NAME             | CONSTRAINT_NAME           | COLUMN_NAME                  | REFERENCED_TABLE_NAME | REFERENCED_COLUMN_NAME   |
+------------------------+---------------------------+------------------------------+-----------------------+--------------------------+
| patient                | PRIMARY                   | patient_id                   | NULL                  | NULL                     |
| patient                | fk_patient_diagnosis      | primary_diagnosis_disease_id | disease               | disease_id               |
| sample_variant_call    | PRIMARY                   | sample_variant_call_id       | NULL                  | NULL                     |
| sample_variant_call    | uq_svc_se_var_type        | sequencing_experiment_id     | NULL                  | NULL                     |
| sample_variant_call    | uq_svc_se_var_type        | variant_id                   | NULL                  | NULL                     |
| sample_variant_call    | uq_svc_se_var_type        | cell_type_id                 | NULL                  | NULL                     |
| sample_variant_call    | fk_svc_celltype           | cell_type_id                 | cell_type             | cell_type_id             |
| sample_variant_call    | fk_svc_se                 | sequencing_experiment_id     | sequencing_experiment | sequencing_experiment_id |
| sample_variant_call    | fk_svc_variant            | variant_id                   | variants              | variant_id               |
| sample_variant_summary | PRIMARY                   | sample_variant_summary_id    | NULL                  | NULL                     |
| sample_variant_summary | uq_svsum_se_var_type      | sequencing_experiment_id     | NULL                  | NULL                     |
| sample_variant_summary | uq_svsum_se_var_type      | variant_id                   | NULL                  | NULL                     |
| sample_variant_summary | uq_svsum_se_var_type      | cell_type_id                 | NULL                  | NULL                     |
| sample_variant_summary | fk_svsum_celltype         | cell_type_id                 | cell_type             | cell_type_id             |
| sample_variant_summary | fk_svsum_refpaper         | ref_paper_id                 | reference_paper       | ref_paper_id             |
| sample_variant_summary | fk_svsum_se               | sequencing_experiment_id     | sequencing_experiment | sequencing_experiment_id |
| sample_variant_summary | fk_svsum_variant          | variant_id                   | variants              | variant_id               |
| variant_annotation     | PRIMARY                   | ann_id                       | NULL                  | NULL                     |
| variant_annotation     | uq_va_tool_tx             | variant_id                   | NULL                  | NULL                     |
| variant_annotation     | uq_va_tool_tx             | transcript_id                | NULL                  | NULL                     |
| variant_annotation     | uq_va_tool_tx             | source_name                  | NULL                  | NULL                     |
| variant_annotation     | fk_va_gene                | gene_id                      | genes                 | gene_id                  |
| variant_annotation     | fk_va_transcript          | transcript_id                | transcripts           | transcript_id            |
| variant_annotation     | fk_va_variant             | variant_id                   | variants              | variant_id               |
| variant_freq           | PRIMARY                   | variant_freq_id              | NULL                  | NULL                     |
| variant_freq           | uq_vf_variant_cohort_pop  | variant_id                   | NULL                  | NULL                     |
| variant_freq           | uq_vf_variant_cohort_pop  | cohort_name                  | NULL                  | NULL                     |
| variant_freq           | uq_vf_variant_cohort_pop  | population_code              | NULL                  | NULL                     |
| variant_freq           | fk_vf_variant             | variant_id                   | variants              | variant_id               |
| variants               | PRIMARY                   | variant_id                   | NULL                  | NULL                     |
| variants               | uq_variant_build_pos_hash | ref_genome_id                | NULL                  | NULL                     |
| variants               | uq_variant_build_pos_hash | chrom                        | NULL                  | NULL                     |
| variants               | uq_variant_build_pos_hash | pos                          | NULL                  | NULL                     |
| variants               | uq_variant_build_pos_hash | ref_alt_hash                 | NULL                  | NULL                     |
| variants               | fk_variants_build         | ref_genome_id                | reference_genome      | ref_genome_id            |
| variants               | fk_variants_vtype         | variant_type_id              | variant_type          | variant_type_id          |
+------------------------+---------------------------+------------------------------+-----------------------+--------------------------+
36 rows in set (0.035 sec)

mysql>
mysql> -- All secondary indexes on those tables (excludes PK which is index_name='PRIMARY')
Query OK, 0 rows affected (0.000 sec)

mysql> SELECT table_name, index_name, column_name, non_unique, seq_in_index
    -> FROM information_schema.STATISTICS
    -> WHERE table_schema = DATABASE()
    ->   AND table_name IN ('sample_variant_call','patient','sample_variant_summary',
    ->                      'variant_annotation','variant_freq','variants')
    -> ORDER BY table_name, index_name, seq_in_index;
+------------------------+----------------------------+------------------------------+------------+--------------+
| TABLE_NAME             | INDEX_NAME                 | COLUMN_NAME                  | NON_UNIQUE | SEQ_IN_INDEX |
+------------------------+----------------------------+------------------------------+------------+--------------+
| patient                | idx_patient_diagnosis      | primary_diagnosis_disease_id |          1 |            1 |
| patient                | PRIMARY                    | patient_id                   |          0 |            1 |
| sample_variant_call    | idx_svc_celltype           | cell_type_id                 |          1 |            1 |
| sample_variant_call    | idx_svc_se                 | sequencing_experiment_id     |          1 |            1 |
| sample_variant_call    | idx_svc_variant            | variant_id                   |          1 |            1 |
| sample_variant_call    | PRIMARY                    | sample_variant_call_id       |          0 |            1 |
| sample_variant_call    | uq_svc_se_var_type         | sequencing_experiment_id     |          0 |            1 |
| sample_variant_call    | uq_svc_se_var_type         | variant_id                   |          0 |            2 |
| sample_variant_call    | uq_svc_se_var_type         | cell_type_id                 |          0 |            3 |
| sample_variant_summary | idx_svsum_celltype         | cell_type_id                 |          1 |            1 |
| sample_variant_summary | idx_svsum_refpaper         | ref_paper_id                 |          1 |            1 |
| sample_variant_summary | idx_svsum_se               | sequencing_experiment_id     |          1 |            1 |
| sample_variant_summary | idx_svsum_variant          | variant_id                   |          1 |            1 |
| sample_variant_summary | PRIMARY                    | sample_variant_summary_id    |          0 |            1 |
| sample_variant_summary | uq_svsum_se_var_type       | sequencing_experiment_id     |          0 |            1 |
| sample_variant_summary | uq_svsum_se_var_type       | variant_id                   |          0 |            2 |
| sample_variant_summary | uq_svsum_se_var_type       | cell_type_id                 |          0 |            3 |
| variant_annotation     | idx_va_gene                | gene_id                      |          1 |            1 |
| variant_annotation     | idx_va_transcript          | transcript_id                |          1 |            1 |
| variant_annotation     | idx_va_variant             | variant_id                   |          1 |            1 |
| variant_annotation     | PRIMARY                    | ann_id                       |          0 |            1 |
| variant_annotation     | uq_va_tool_tx              | variant_id                   |          0 |            1 |
| variant_annotation     | uq_va_tool_tx              | source_name                  |          0 |            2 |
| variant_annotation     | uq_va_tool_tx              | transcript_id                |          0 |            3 |
| variant_freq           | idx_vf_cohort              | cohort_name                  |          1 |            1 |
| variant_freq           | idx_vf_variant             | variant_id                   |          1 |            1 |
| variant_freq           | PRIMARY                    | variant_freq_id              |          0 |            1 |
| variant_freq           | uq_vf_variant_cohort_pop   | variant_id                   |          0 |            1 |
| variant_freq           | uq_vf_variant_cohort_pop   | cohort_name                  |          0 |            2 |
| variant_freq           | uq_vf_variant_cohort_pop   | population_code              |          0 |            3 |
| variants               | fk_variants_vtype          | variant_type_id              |          1 |            1 |
| variants               | idx_variants_build_chr_pos | ref_genome_id                |          1 |            1 |
| variants               | idx_variants_build_chr_pos | chrom                        |          1 |            2 |
| variants               | idx_variants_build_chr_pos | pos                          |          1 |            3 |
| variants               | PRIMARY                    | variant_id                   |          0 |            1 |
| variants               | uq_variant_build_pos_hash  | ref_genome_id                |          0 |            1 |
| variants               | uq_variant_build_pos_hash  | chrom                        |          0 |            2 |
| variants               | uq_variant_build_pos_hash  | pos                          |          0 |            3 |
| variants               | uq_variant_build_pos_hash  | ref_alt_hash                 |          0 |            4 |
+------------------------+----------------------------+------------------------------+------------+--------------+
39 rows in set (0.021 sec)

mysql>
    -> FROM information_schema.KEY_COLUMN_USAGE
    -> WHERE table_schema = DATABASE()
    ->   AND table_name IN ('sample_variant_call','patient','sample_variant_summary',
    ->                      'variant_annotation','variant_freq','variants');
+------------------------+---------------------------+------------------------------+-----------------------+--------------------------+
| TABLE_NAME             | CONSTRAINT_NAME           | COLUMN_NAME                  | REFERENCED_TABLE_NAME | REFERENCED_COLUMN_NAME   |
+------------------------+---------------------------+------------------------------+-----------------------+--------------------------+
| patient                | PRIMARY                   | patient_id                   | NULL                  | NULL                     |
| patient                | fk_patient_diagnosis      | primary_diagnosis_disease_id | disease               | disease_id               |
| sample_variant_call    | PRIMARY                   | sample_variant_call_id       | NULL                  | NULL                     |
| sample_variant_call    | uq_svc_se_var_type        | sequencing_experiment_id     | NULL                  | NULL                     |
| sample_variant_call    | uq_svc_se_var_type        | variant_id                   | NULL                  | NULL                     |
| sample_variant_call    | uq_svc_se_var_type        | cell_type_id                 | NULL                  | NULL                     |
| sample_variant_call    | fk_svc_celltype           | cell_type_id                 | cell_type             | cell_type_id             |
| sample_variant_call    | fk_svc_se                 | sequencing_experiment_id     | sequencing_experiment | sequencing_experiment_id |
| sample_variant_call    | fk_svc_variant            | variant_id                   | variants              | variant_id               |
| sample_variant_summary | PRIMARY                   | sample_variant_summary_id    | NULL                  | NULL                     |
| sample_variant_summary | uq_svsum_se_var_type      | sequencing_experiment_id     | NULL                  | NULL                     |
| sample_variant_summary | uq_svsum_se_var_type      | variant_id                   | NULL                  | NULL                     |
| sample_variant_summary | uq_svsum_se_var_type      | cell_type_id                 | NULL                  | NULL                     |
| sample_variant_summary | fk_svsum_celltype         | cell_type_id                 | cell_type             | cell_type_id             |
| sample_variant_summary | fk_svsum_refpaper         | ref_paper_id                 | reference_paper       | ref_paper_id             |
| sample_variant_summary | fk_svsum_se               | sequencing_experiment_id     | sequencing_experiment | sequencing_experiment_id |
| sample_variant_summary | fk_svsum_variant          | variant_id                   | variants              | variant_id               |
| variant_annotation     | PRIMARY                   | ann_id                       | NULL                  | NULL                     |
| variant_annotation     | uq_va_tool_tx             | variant_id                   | NULL                  | NULL                     |
| variant_annotation     | uq_va_tool_tx             | transcript_id                | NULL                  | NULL                     |
| variant_annotation     | uq_va_tool_tx             | source_name                  | NULL                  | NULL                     |
| variant_annotation     | fk_va_gene                | gene_id                      | genes                 | gene_id                  |
| variant_annotation     | fk_va_transcript          | transcript_id                | transcripts           | transcript_id            |
| variant_annotation     | fk_va_variant             | variant_id                   | variants              | variant_id               |
| variant_freq           | PRIMARY                   | variant_freq_id              | NULL                  | NULL                     |
| variant_freq           | uq_vf_variant_cohort_pop  | variant_id                   | NULL                  | NULL                     |
| variant_freq           | uq_vf_variant_cohort_pop  | cohort_name                  | NULL                  | NULL                     |
| variant_freq           | uq_vf_variant_cohort_pop  | population_code              | NULL                  | NULL                     |
| variant_freq           | fk_vf_variant             | variant_id                   | variants              | variant_id               |
| variants               | PRIMARY                   | variant_id                   | NULL                  | NULL                     |
| variants               | uq_variant_build_pos_hash | ref_genome_id                | NULL                  | NULL                     |
| variants               | uq_variant_build_pos_hash | chrom                        | NULL                  | NULL                     |
| variants               | uq_variant_build_pos_hash | pos                          | NULL                  | NULL                     |
| variants               | uq_variant_build_pos_hash | ref_alt_hash                 | NULL                  | NULL                     |
| variants               | fk_variants_build         | ref_genome_id                | reference_genome      | ref_genome_id            |
| variants               | fk_variants_vtype         | variant_type_id              | variant_type          | variant_type_id          |
+------------------------+---------------------------+------------------------------+-----------------------+--------------------------+
36 rows in set (0.035 sec)

mysql>
mysql> -- All secondary indexes on those tables (excludes PK which is index_name='PRIMARY')
Query OK, 0 rows affected (0.000 sec)

mysql> SELECT table_name, index_name, column_name, non_unique, seq_in_index
    -> FROM information_schema.STATISTICS
    -> WHERE table_schema = DATABASE()
    ->   AND table_name IN ('sample_variant_call','patient','sample_variant_summary',
    ->                      'variant_annotation','variant_freq','variants')
    -> ORDER BY table_name, index_name, seq_in_index;
+------------------------+----------------------------+------------------------------+------------+--------------+
| TABLE_NAME             | INDEX_NAME                 | COLUMN_NAME                  | NON_UNIQUE | SEQ_IN_INDEX |
+------------------------+----------------------------+------------------------------+------------+--------------+
| patient                | idx_patient_diagnosis      | primary_diagnosis_disease_id |          1 |            1 |
| patient                | PRIMARY                    | patient_id                   |          0 |            1 |
| sample_variant_call    | idx_svc_celltype           | cell_type_id                 |          1 |            1 |
| sample_variant_call    | idx_svc_se                 | sequencing_experiment_id     |          1 |            1 |
| sample_variant_call    | idx_svc_variant            | variant_id                   |          1 |            1 |
| sample_variant_call    | PRIMARY                    | sample_variant_call_id       |          0 |            1 |
| sample_variant_call    | uq_svc_se_var_type         | sequencing_experiment_id     |          0 |            1 |
| sample_variant_call    | uq_svc_se_var_type         | variant_id                   |          0 |            2 |
| sample_variant_call    | uq_svc_se_var_type         | cell_type_id                 |          0 |            3 |
| sample_variant_summary | idx_svsum_celltype         | cell_type_id                 |          1 |            1 |
| sample_variant_summary | idx_svsum_refpaper         | ref_paper_id                 |          1 |            1 |
| sample_variant_summary | idx_svsum_se               | sequencing_experiment_id     |          1 |            1 |
| sample_variant_summary | idx_svsum_variant          | variant_id                   |          1 |            1 |
| sample_variant_summary | PRIMARY                    | sample_variant_summary_id    |          0 |            1 |
| sample_variant_summary | uq_svsum_se_var_type       | sequencing_experiment_id     |          0 |            1 |
| sample_variant_summary | uq_svsum_se_var_type       | variant_id                   |          0 |            2 |
| sample_variant_summary | uq_svsum_se_var_type       | cell_type_id                 |          0 |            3 |
| variant_annotation     | idx_va_gene                | gene_id                      |          1 |            1 |
| variant_annotation     | idx_va_transcript          | transcript_id                |          1 |            1 |
| variant_annotation     | idx_va_variant             | variant_id                   |          1 |            1 |
| variant_annotation     | PRIMARY                    | ann_id                       |          0 |            1 |
| variant_annotation     | uq_va_tool_tx              | variant_id                   |          0 |            1 |
| variant_annotation     | uq_va_tool_tx              | source_name                  |          0 |            2 |
| variant_annotation     | uq_va_tool_tx              | transcript_id                |          0 |            3 |
| variant_freq           | idx_vf_cohort              | cohort_name                  |          1 |            1 |
| variant_freq           | idx_vf_variant             | variant_id                   |          1 |            1 |
| variant_freq           | PRIMARY                    | variant_freq_id              |          0 |            1 |
| variant_freq           | uq_vf_variant_cohort_pop   | variant_id                   |          0 |            1 |
| variant_freq           | uq_vf_variant_cohort_pop   | cohort_name                  |          0 |            2 |
| variant_freq           | uq_vf_variant_cohort_pop   | population_code              |          0 |            3 |
| variants               | fk_variants_vtype          | variant_type_id              |          1 |            1 |
| variants               | idx_variants_build_chr_pos | ref_genome_id                |          1 |            1 |
| variants               | idx_variants_build_chr_pos | chrom                        |          1 |            2 |
| variants               | idx_variants_build_chr_pos | pos                          |          1 |            3 |
| variants               | PRIMARY                    | variant_id                   |          0 |            1 |
| variants               | uq_variant_build_pos_hash  | ref_genome_id                |          0 |            1 |
| variants               | uq_variant_build_pos_hash  | chrom                        |          0 |            2 |
| variants               | uq_variant_build_pos_hash  | pos                          |          0 |            3 |
| variants               | uq_variant_build_pos_hash  | ref_alt_hash                 |          0 |            4 |
+------------------------+----------------------------+------------------------------+------------+--------------+
39 rows in set (0.021 sec)

m
-- Purpose: Apply Nov 2025 schema adjustments to finalized 16-table ER.

-- 1) sample_variant_call: drop caller_name, call_date, filters
ALTER TABLE sample_variant_call
  DROP COLUMN caller_name,
  DROP COLUMN call_date,
  DROP COLUMN filters;

-- 2) patient: rename age_years -> age
ALTER TABLE patient
  RENAME COLUMN age_years TO age;

-- 3) sample_variant_summary: add qc_status, somatic_source
-- (Use flexible VARCHARs for now; you can tighten to ENUMs later if you like.)
ALTER TABLE sample_variant_summary
  ADD COLUMN qc_status VARCHAR(32) NULL,
  ADD COLUMN somatic_source VARCHAR(32) NULL;

-- 4) variant_annotation: rename ann_id -> annotation_id, add impact
ALTER TABLE variant_annotation
  RENAME COLUMN ann_id TO annotation_id;

ALTER TABLE variant_annotation
  ADD COLUMN impact VARCHAR(32) NULL;

-- 5) variant_freq: drop population_code, source_version
ALTER TABLE variant_freq
  DROP COLUMN population_code,
  DROP COLUMN source_version;

-- 6) variants: drop ref_alt_hash
ALTER TABLE variants
  DROP COLUMN ref_alt_hash;
