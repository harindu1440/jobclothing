-- ============================================================
--  JobClothing - Database Installation Script
--  Run this once against your FiveM/MySQL database.
-- ============================================================

CREATE TABLE IF NOT EXISTS `jobclothing_peds` (
  `id`          INT(11)      NOT NULL AUTO_INCREMENT,
  `model`       VARCHAR(64)  NOT NULL,
  `label`       VARCHAR(128) NOT NULL DEFAULT '',
  `x`           FLOAT        NOT NULL DEFAULT 0,
  `y`           FLOAT        NOT NULL DEFAULT 0,
  `z`           FLOAT        NOT NULL DEFAULT 0,
  `heading`     FLOAT        NOT NULL DEFAULT 0,
  `created_by`  VARCHAR(64)  NOT NULL DEFAULT '',
  `created_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `jobclothing_uniforms` (
  `id`           INT(11)      NOT NULL AUTO_INCREMENT,
  `ped_id`       INT(11)      NOT NULL,
  `job_name`     VARCHAR(64)  NOT NULL,
  `job_grade`    INT(11)      NOT NULL DEFAULT 0,
  `uniform_name` VARCHAR(128) NOT NULL DEFAULT 'Default',
  `outfit_data`  LONGTEXT     NOT NULL,
  `created_at`   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_ped_id`   (`ped_id`),
  KEY `idx_job_grade` (`job_name`, `job_grade`),
  CONSTRAINT `fk_uniform_ped`
    FOREIGN KEY (`ped_id`) REFERENCES `jobclothing_peds` (`id`)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
