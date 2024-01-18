DROP TABLE IF EXISTS `motels`;
CREATE TABLE IF NOT EXISTS `motels` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `room_name` varchar(100) DEFAULT 'Room #1',
  `roomid` varchar(50) DEFAULT 'bh-1',
  `renter` varchar(100) DEFAULT 'John Doe',
  `renter_citizenid` varchar(50) DEFAULT 'ABC12345',
  `stash` varchar(2500) DEFAULT '[]',
  `rentedTime` int(11) DEFAULT 86400,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;