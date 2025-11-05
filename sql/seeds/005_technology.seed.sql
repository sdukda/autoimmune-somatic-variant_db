USE autoimmune_db;

INSERT INTO technology (platform) VALUES
    ('WES'), 
    ('WGS'), 
    ('10x_scRNA'), 
    ('Smart-seq2')
ON DUPLICATE KEY UPDATE
   platform = VALUES(platform);
