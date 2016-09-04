CREATE TABLE IF NOT EXISTS `users` (
  `user_id` mediumint(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'User Id',
  `first_name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Users first name',
  `last_name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Users last name',
  `email` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Users email address',
  `registration_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Date the user registered',
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Users table' AUTO_INCREMENT=1 ;

