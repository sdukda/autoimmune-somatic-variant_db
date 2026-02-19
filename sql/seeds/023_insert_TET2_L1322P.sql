-- TET2 p.Leu1322Pro (L1322P) — GRCh37 mapping

INSERT INTO literature_driver_variants
(
  study_id,
  study_name_short,
  gene_symbol,
  protein_change,
  cDNA_HGVS,

  paper_ref_genome_id,
  paper_chrom,
  paper_pos,
  paper_ref,
  paper_alt,

  variant_type,
  variant_impact,
  is_driver,

  disease_id,
  cell_type_name,
  evidence_type,

  notes,
  Remarks
)
SELECT
  s.study_id,
  'REPLACE_STUDY_SHORT' AS study_name_short,
  'TET2',
  'p.Leu1322Pro',
  'NM_017628.4:c.3965T>C',

  rg.ref_genome_id,
  'chr4',
  '106182926',
  'T',
  'C',

  'missense SNV',
  'missense',
  'Somatic disease driver',

  d.disease_id,
  'REPLACE_CELL_TYPE',
  'Literature-reported',

  'Paper reports NP_060098.3:p.Leu1322Pro and NM_017628.4:c.3965T>C. Transcript mismatch; Ensembl mapping consistent with NM_001127208.3:c.3965T>C giving chr4:106182926 T>C (GRCh37).',
  'Curated insert; GRCh37 paper coordinate stored; transcript mismatch documented.'
FROM study s
JOIN disease d
JOIN reference_genome rg
WHERE rg.ref_genome_name = 'GRCh37'
  AND s.study_name = 'REPLACE_STUDY_NAME'
  AND d.disease_name = 'REPLACE_DISEASE_NAME';
