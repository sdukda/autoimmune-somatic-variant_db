-- 003_alter_schema_2025_11_idempotent.sql
-- Idempotent, no stored procedures, safe on MySQL 5.7+ and 8.0+
-- It conditionally drops indexes/columns and renames columns using dynamic SQL.

-- Detect 8.0+ for nicer RENAME COLUMN usage (fallback to CHANGE on 5.7)
SET @is80 := (SELECT CASE WHEN VERSION() REGEXP '^8\\.' THEN 1 ELSE 0 END);

-- ============================================================
-- sample_variant_call: drop caller_name, call_date, filters
-- ============================================================
-- caller_name
SET @exists := (SELECT COUNT(*) FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE()
                  AND TABLE_NAME   = 'sample_variant_call'
                  AND COLUMN_NAME  = 'caller_name');
SET @sql := IF(@exists>0,
  'ALTER TABLE `sample_variant_call` DROP COLUMN `caller_name`',
  'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- call_date
SET @exists := (SELECT COUNT(*) FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE()
                  AND TABLE_NAME   = 'sample_variant_call'
                  AND COLUMN_NAME  = 'call_date');
SET @sql := IF(@exists>0,
  'ALTER TABLE `sample_variant_call` DROP COLUMN `call_date`',
  'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- filters
SET @exists := (SELECT COUNT(*) FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE()
                  AND TABLE_NAME   = 'sample_variant_call'
                  AND COLUMN_NAME  = 'filters');
SET @sql := IF(@exists>0,
  'ALTER TABLE `sample_variant_call` DROP COLUMN `filters`',
  'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ============================================================
-- patient: rename age_years -> age  (8.0: RENAME COLUMN; 5.7: CHANGE with type)
-- ============================================================
-- Only rename if old exists and new doesn't
SET @old_exists := (SELECT COUNT(*) FROM information_schema.COLUMNS
                    WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='patient' AND COLUMN_NAME='age_years');
SET @new_exists := (SELECT COUNT(*) FROM information_schema.COLUMNS
                    WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='patient' AND COLUMN_NAME='age');

-- Build column type DDL for 5.7 CHANGE fallback
SET @coldef := (SELECT CONCAT(COLUMN_TYPE, ' ',
                              IF(IS_NULLABLE='YES','NULL','NOT NULL'),
                              IF(COLUMN_DEFAULT IS NOT NULL, CONCAT(' DEFAULT ', QUOTE(COLUMN_DEFAULT)), ''),
                              IF(EXTRA<>'', CONCAT(' ', EXTRA), '')
                         )
                FROM information_schema.COLUMNS
               WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='patient' AND COLUMN_NAME='age_years'
               LIMIT 1);

SET @sql := CASE
  WHEN @old_exists=1 AND @new_exists=0 AND @is80=1
    THEN 'ALTER TABLE `patient` RENAME COLUMN `age_years` TO `age`'
  WHEN @old_exists=1 AND @new_exists=0 AND @is80=0
    THEN CONCAT('ALTER TABLE `patient` CHANGE COLUMN `age_years` `age` ', COALESCE(@coldef,'INT NULL'))
  ELSE 'DO 0'
END;
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ============================================================
-- sample_variant_summary: add qc_status, somatic_source
-- ============================================================
-- qc_status
SET @exists := (SELECT COUNT(*) FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sample_variant_summary' AND COLUMN_NAME='qc_status');
SET @sql := IF(@exists=0,
  'ALTER TABLE `sample_variant_summary` ADD COLUMN `qc_status` VARCHAR(32) NULL',
  'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- somatic_source
SET @exists := (SELECT COUNT(*) FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sample_variant_summary' AND COLUMN_NAME='somatic_source');
SET @sql := IF(@exists=0,
  'ALTER TABLE `sample_variant_summary` ADD COLUMN `somatic_source` VARCHAR(32) NULL',
  'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ============================================================
-- variant_annotation: rename ann_id -> annotation_id; add impact
-- ============================================================
-- Rename PK if needed (8.0 or 5.7 fallback)
SET @old_exists := (SELECT COUNT(*) FROM information_schema.COLUMNS
                    WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='variant_annotation' AND COLUMN_NAME='ann_id');
SET @new_exists := (SELECT COUNT(*) FROM information_schema.COLUMNS
                    WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='variant_annotation' AND COLUMN_NAME='annotation_id');

SET @coldef := (SELECT CONCAT(COLUMN_TYPE, ' ',
                              IF(IS_NULLABLE='YES','NULL','NOT NULL'),
                              IF(COLUMN_DEFAULT IS NOT NULL, CONCAT(' DEFAULT ', QUOTE(COLUMN_DEFAULT)), ''),
                              IF(EXTRA<>'', CONCAT(' ', EXTRA), '')
                         )
                FROM information_schema.COLUMNS
               WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='variant_annotation' AND COLUMN_NAME='ann_id'
               LIMIT 1);

SET @sql := CASE
  WHEN @old_exists=1 AND @new_exists=0 AND @is80=1
    THEN 'ALTER TABLE `variant_annotation` RENAME COLUMN `ann_id` TO `annotation_id`'
  WHEN @old_exists=1 AND @new_exists=0 AND @is80=0
    THEN CONCAT('ALTER TABLE `variant_annotation` CHANGE COLUMN `ann_id` `annotation_id` ', COALESCE(@coldef,'BIGINT NOT NULL'))
  ELSE 'DO 0'
END;
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- impact
SET @exists := (SELECT COUNT(*) FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='variant_annotation' AND COLUMN_NAME='impact');
SET @sql := IF(@exists=0,
  'ALTER TABLE `variant_annotation` ADD COLUMN `impact` VARCHAR(32) NULL',
  'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ============================================================
-- variant_freq: drop UNIQUE uq_vf_variant_cohort_pop, then drop columns
-- ============================================================
-- unique index
SET @idx_exists := (SELECT COUNT(*) FROM information_schema.STATISTICS
                    WHERE TABLE_SCHEMA=DATABASE()
                      AND TABLE_NAME='variant_freq'
                      AND INDEX_NAME='uq_vf_variant_cohort_pop');
SET @sql := IF(@idx_exists>0,
  'ALTER TABLE `variant_freq` DROP INDEX `uq_vf_variant_cohort_pop`',
  'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- population_code
SET @exists := (SELECT COUNT(*) FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='variant_freq' AND COLUMN_NAME='population_code');
SET @sql := IF(@exists>0,
  'ALTER TABLE `variant_freq` DROP COLUMN `population_code`',
  'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- source_version
SET @exists := (SELECT COUNT(*) FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='variant_freq' AND COLUMN_NAME='source_version');
SET @sql := IF(@exists>0,
  'ALTER TABLE `variant_freq` DROP COLUMN `source_version`',
  'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- (Optional) replacement unique if you need it:
-- ALTER TABLE variant_freq ADD UNIQUE KEY uq_vf_variant_cohort (variant_id, cohort_name);

-- ============================================================
-- variants: drop UNIQUE uq_variant_build_pos_hash, then drop ref_alt_hash
-- ============================================================
SET @idx_exists := (SELECT COUNT(*) FROM information_schema.STATISTICS
                    WHERE TABLE_SCHEMA=DATABASE()
                      AND TABLE_NAME='variants'
                      AND INDEX_NAME='uq_variant_build_pos_hash');
SET @sql := IF(@idx_exists>0,
  'ALTER TABLE `variants` DROP INDEX `uq_variant_build_pos_hash`',
  'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ref_alt_hash
SET @exists := (SELECT COUNT(*) FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='variants' AND COLUMN_NAME='ref_alt_hash');
SET @sql := IF(@exists>0,
  'ALTER TABLE `variants` DROP COLUMN `ref_alt_hash`',
  'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- (Optional) if you use ref/alt columns and want uniqueness:
-- ALTER TABLE variants ADD UNIQUE KEY uq_variant_build_pos_ref_alt (ref_genome_id, chrom, pos, ref, alt);
