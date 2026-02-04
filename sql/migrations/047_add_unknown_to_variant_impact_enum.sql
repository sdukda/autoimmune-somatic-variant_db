USE autoimmune_db;

ALTER TABLE literature_driver_variants
MODIFY COLUMN variant_impact ENUM(
  'missense','nonsense','splice','synonymous','noncoding',
  'frameshift','inframe indel',
  'frameshift insertion','frameshift deletion','frameshift delins',
  'inframe insertion','inframe deletion','inframe delins',
  'intron','utr','promoter','intergenic',
  'unknown'
) COLLATE utf8mb4_unicode_ci DEFAULT NULL;
