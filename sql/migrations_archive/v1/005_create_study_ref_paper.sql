USE autoimmune_db;
CREATE TABLE IF NOT EXISTS study_ref_paper(
study_id        BIGINT NOT NULL,
ref_paper_id    BIGINT NOT NULL,
PRIMARY KEY (study_id,ref_paper_id),
CONSTRAINT fk_srp_study FOREIGN KEY (study_id) REFERENCES study(study_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
CONSTRAINT fk_srp_refpaper FOREIGN KEY (ref_paper_id) REFERENCES ref_paper(ref_paper_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB;

