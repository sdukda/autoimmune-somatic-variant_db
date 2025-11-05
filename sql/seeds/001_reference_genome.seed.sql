USE autoimmune_db;
INSERT INTO reference_genome (assembly_name, version) VALUES
    ('GRCh37', NULL,  NULL, NULL), 
    ('GRCh38', NULL, NULL, NULL), 
    ('GRCh38','p14', NULL, 'latest patch as of writing')
ON DUPLICATE KEY UPDATE
    build_date = VALUES(build_date),
    note       = VALUES(note);
