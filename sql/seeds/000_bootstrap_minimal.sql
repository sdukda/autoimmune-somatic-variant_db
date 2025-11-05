USE autoimmune_db;

-- ---------- 0. helper: make sure core lookup rows exist ----------

-- reference_genome: ensure GRCh38 exists
INSERT INTO reference_genome (assembly_name)
SELECT 'GRCh38'
WHERE NOT EXISTS (
  SELECT 1 FROM reference_genome
  WHERE assembly_name = 'GRCh38'
);

-- variant_type: ensure SNV exists (adjust if your table also has label/description columns)
INSERT INTO variant_type (code)
SELECT 'SNV'
WHERE NOT EXISTS (
  SELECT 1 FROM variant_type
  WHERE code = 'SNV'
);

-- disease: ensure a generic autoimmune row exists
INSERT INTO disease (disease_name)
SELECT 'Autoimmune, unspecified'
WHERE NOT EXISTS (
  SELECT 1 FROM disease
  WHERE disease_name = 'Autoimmune, unspecified'
);

-- ---------- 1. capture the IDs we’ll need ----------

-- ref genome id for GRCh38
SELECT @rg := ref_genome_id
FROM reference_genome
WHERE assembly_name = 'GRCh38'
LIMIT 1;

-- variant_type_id for SNV
SELECT @vt := variant_type_id
FROM variant_type
WHERE code = 'SNV'
LIMIT 1;

-- disease_id for our generic autoimmune disease
SELECT @dz := disease_id
FROM disease
WHERE disease_name = 'Autoimmune, unspecified'
LIMIT 1;

-- ---------- 2. create / get a study ----------

-- create "Demo study" if missing
INSERT INTO study (name, description)
SELECT 'Demo study', 'Bootstrap study for testing FKs and joins'
WHERE NOT EXISTS (
  SELECT 1 FROM study
  WHERE name = 'Demo study'
);

-- capture study_id
SELECT @study := study_id
FROM study
WHERE name = 'Demo study'
LIMIT 1;

-- ---------- 3. create / get a sample under that study ----------

-- insert "Demo sample 1" if missing for that study
INSERT INTO sample (study_id, sample_name)
SELECT @study, 'Demo sample 1'
WHERE NOT EXISTS (
  SELECT 1 FROM sample
  WHERE study_id   = @study
    AND sample_name = 'Demo sample 1'
);

-- capture sample_id
SELECT @sample := sample_id
FROM sample
WHERE study_id = @study
  AND sample_name = 'Demo sample 1'
LIMIT 1;

-- ---------- 4. create / get a variant ----------

-- we'll use chr6:138197096 A>G as a fake example call
INSERT INTO variants (ref_genome_id, chrom, pos, ref, alt, variant_type_id)
SELECT @rg, '6', 138197096, 'A', 'G', @vt
WHERE NOT EXISTS (
  SELECT 1
  FROM variants v
  WHERE v.ref_genome_id = @rg
    AND v.chrom         = '6'
    AND v.pos           = 138197096
    AND v.ref           = 'A'
    AND v.alt           = 'G'
);

-- capture variant_id
SELECT @var := variant_id
FROM variants
WHERE ref_genome_id = @rg
  AND chrom         = '6'
  AND pos           = 138197096
  AND ref           = 'A'
  AND alt           = 'G'
LIMIT 1;

-- ---------- 5. add sample_annotation rows ----------

-- A) sample-level batch info
INSERT INTO sample_annotation (sample_id, ann_key, ann_value)
SELECT @sample, 'batch', 'B3'
WHERE NOT EXISTS (
  SELECT 1 FROM sample_annotation
  WHERE sample_id = @sample
    AND ann_key   = 'batch'
    AND ann_value = 'B3'
    AND variant_id IS NULL
    AND disease_id IS NULL
);

-- B) variant-specific call (zygosity)
INSERT INTO sample_annotation (sample_id, variant_id, ann_key, ann_value)
SELECT @sample, @var, 'zygosity', 'het'
WHERE NOT EXISTS (
  SELECT 1 FROM sample_annotation
  WHERE sample_id  = @sample
    AND variant_id = @var
    AND ann_key    = 'zygosity'
);

-- C) disease label for this sample
INSERT INTO sample_annotation (sample_id, disease_id, ann_key, ann_value)
SELECT @sample, @dz, 'diagnosis', 'SLE'
WHERE NOT EXISTS (
  SELECT 1 FROM sample_annotation
  WHERE sample_id  = @sample
    AND disease_id = @dz
    AND ann_key    = 'diagnosis'
);

-- ---------- 6. show summary of what's now in the DB ----------

SELECT
  s.study_id,
  s.name            AS study_name,
  smp.sample_id,
  smp.sample_name,
  v.variant_id,
  v.chrom,
  v.pos,
  v.ref,
  v.alt,
  dz.disease_id,
  dz.disease_name
FROM study s
JOIN sample smp
  ON smp.study_id = s.study_id
LEFT JOIN sample_annotation sa_var
  ON sa_var.sample_id  = smp.sample_id
 AND sa_var.ann_key    = 'zygosity'
LEFT JOIN variants v
  ON v.variant_id = sa_var.variant_id
LEFT JOIN disease dz
  ON dz.disease_id = @dz
WHERE s.study_id = @study
LIMIT 20;

-- also inspect the raw annotations
SELECT * FROM sample_annotation
WHERE sample_id = @sample
ORDER BY sample_annotation_id;
