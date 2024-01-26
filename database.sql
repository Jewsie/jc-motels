/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

-- Dumping structure for table s25_RoleplayFiveM.jc_motels
DROP TABLE IF EXISTS `jc_motels`;
CREATE TABLE IF NOT EXISTS `jc_motels` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `motel` varchar(250) DEFAULT NULL,
  `room_name` varchar(100) DEFAULT 'Room #1',
  `roomid` varchar(50) DEFAULT 'bh-1',
  `renter` varchar(100) DEFAULT 'John Doe',
  `renter_citizenid` varchar(50) DEFAULT 'ABC12345',
  `rentedTime` int(11) DEFAULT 86400,
  `funds` int(11) DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table s25_RoleplayFiveM.jc_motels: ~0 rows (approximately)

-- Dumping structure for table s25_RoleplayFiveM.jc_ownedmotels
DROP TABLE IF EXISTS `jc_ownedmotels`;
CREATE TABLE IF NOT EXISTS `jc_ownedmotels` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `motel` varchar(250) DEFAULT NULL,
  `motel_name` varchar(250) DEFAULT NULL,
  `owner` varchar(250) DEFAULT NULL,
  `funds` int(11) DEFAULT 0,
  `boughtInterval` int(11) DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table s25_RoleplayFiveM.jc_ownedmotels: ~0 rows (approximately)

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
