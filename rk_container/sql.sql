
CREATE TABLE IF NOT EXISTS `containers` (
  `container_id` int NOT NULL AUTO_INCREMENT,
  `container_number` varchar(255) NOT NULL,
  `pin` varchar(255) NOT NULL,
  `blip_x` float NOT NULL,
  `blip_y` float NOT NULL,
  `blip_z` float NOT NULL,
  `owner` varchar(255) NOT NULL,
  PRIMARY KEY (`container_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb3;

