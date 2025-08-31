# ************************************************************
# Sequel Ace SQL dump
# Version 20058
#
# https://sequel-ace.com/
# https://github.com/Sequel-Ace/Sequel-Ace
#
# Host: localhost (MySQL 11.3.2-MariaDB-1:11.3.2+maria~ubu2204)
# Database: References
# Generation Time: 2025-08-29 11:17:15 +0000
# ************************************************************


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
SET NAMES utf8mb4;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE='NO_AUTO_VALUE_ON_ZERO', SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


# Dump of table References
# ------------------------------------------------------------

CREATE TABLE `References` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(1024) DEFAULT NULL,
  `authors` varchar(1024) DEFAULT NULL,
  `year` year(4) DEFAULT NULL,
  `document` longblob DEFAULT NULL COMMENT 'Single file (in most cases PDF)',
  `file extension` char(11) DEFAULT NULL,
  `url` varchar(1024) DEFAULT NULL,
  `type` varchar(128) DEFAULT NULL,
  `notes` varchar(1024) DEFAULT NULL,
  `tags` varchar(1024) DEFAULT NULL,
  `book` varchar(1024) DEFAULT NULL,
  `citations` int(11) unsigned DEFAULT NULL,
  `bibfile` varchar(1024) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;




/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
