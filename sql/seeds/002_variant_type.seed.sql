USE autoimmune_db;

INSERT INTO variant_type (code, label) VALUES
    ('SNV', 'Single nucleotide variant'),
    ('INDEL','Insertion/Deletion'),
    ('SV','Structural variant'),
    ('CNV','Copy-number variant');
ON DUPLICATE KEY UPDATE
    label = VALUE(label);
