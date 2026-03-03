CREATE TABLE IF NOT EXISTS `vehicle_persistence` (
    `plate` VARCHAR(255) NOT NULL,
    `coords` LONGTEXT DEFAULT NULL,
    `props` LONGTEXT DEFAULT NULL,
    `engine` INT(11) DEFAULT 1000,
    `body` INT(11) DEFAULT 1000,
    `fuel` INT(11) DEFAULT 100,
    `lockstatus` INT(11) DEFAULT 1,
    PRIMARY KEY (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
