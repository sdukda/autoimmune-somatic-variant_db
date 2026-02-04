INSERT IGNORE INTO literature_variant_study (
  literature_variant_id,
  study_id,
  evidence_type,
  notes
)
SELECT
  ldv.literature_variant_id,
  st.study_id,
  st.evidence_type,
  CONCAT('Imported from staging: ', st.study_name_short)
FROM stg_literature_driver_variants st
JOIN literature_driver_variants ldv
  ON ldv.natural_key_sha = UNHEX(
       SHA2(
         CONCAT_WS('|',
           st.study_id,
           COALESCE(st.gene_symbol,''),
           COALESCE(st.cDNA_HGVS,''),
           COALESCE(st.protein_change,''),
           COALESCE(st.paper_chrom,''),
           COALESCE(st.paper_pos,''),
           COALESCE(st.paper_ref,''),
           COALESCE(st.paper_alt,''),
           COALESCE(st.disease_name,''),
           COALESCE(st.cell_type_name,'')
         ),
         256
       )
     );
