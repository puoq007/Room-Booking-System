-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Nov 27, 2024 at 12:00 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `reservation`
--

-- --------------------------------------------------------

--
-- Table structure for table `information`
--

CREATE TABLE `information` (
  `id` tinyint(10) UNSIGNED NOT NULL,
  `user_id` tinyint(10) NOT NULL,
  `room_id` tinyint(10) UNSIGNED NOT NULL,
  `slot` enum('slot_1','slot_2','slot_3','slot_4') NOT NULL,
  `borrowed_by` tinyint(3) UNSIGNED DEFAULT NULL,
  `borrowed_date` datetime NOT NULL,
  `approved_by` tinyint(3) UNSIGNED DEFAULT NULL,
  `status` tinyint(2) NOT NULL COMMENT '1 = approve, 2 = disapprove'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `information`
--

INSERT INTO `information` (`id`, `user_id`, `room_id`, `slot`, `borrowed_by`, `borrowed_date`, `approved_by`, `status`) VALUES
(32, 14, 2, 'slot_1', 14, '2024-11-20 09:30:39', 13, 2),
(33, 14, 3, 'slot_4', 14, '2024-11-20 09:37:35', 13, 1),
(34, 14, 4, 'slot_4', 14, '2024-11-20 09:38:56', 13, 2),
(36, 1, 2, 'slot_1', 1, '2024-11-27 10:53:16', NULL, 0),
(37, 12, 4, 'slot_3', 12, '2024-11-27 10:53:16', 11, 1);

-- --------------------------------------------------------

--
-- Table structure for table `room`
--

CREATE TABLE `room` (
  `room_id` tinyint(10) UNSIGNED NOT NULL,
  `room_name` varchar(255) NOT NULL,
  `size` tinyint(1) NOT NULL COMMENT '1 = S, 2 = M, 3 = L',
  `image` varchar(255) NOT NULL,
  `slot_1` enum('free','pending','reserve','disable','full') NOT NULL COMMENT '8:00-10:00',
  `slot_2` enum('free','pending','reserve','disable','full') NOT NULL COMMENT '10:00-12:00',
  `slot_3` enum('free','pending','reserve','disable','full') NOT NULL COMMENT '13:00-15:00',
  `slot_4` enum('free','pending','reserve','disable','full') NOT NULL COMMENT '15:00-17:00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `room`
--

INSERT INTO `room` (`room_id`, `room_name`, `size`, `image`, `slot_1`, `slot_2`, `slot_3`, `slot_4`) VALUES
(1, 'S1 101', 3, 'large.jpeg', 'free', 'free', 'free', 'free'),
(2, 'S1 102', 1, 'small.jpeg', 'pending', 'free', 'disable', 'free'),
(3, 'S1 103', 1, 'small.jpeg', 'disable', 'disable', 'free', 'free'),
(4, 'S1 104', 2, 'medium.jpeg', 'free', 'free', 'reserve', 'reserve'),
(8, 'S1', 1, '1732646052878.jpg', 'free', 'free', 'free', 'reserve');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `user_id` tinyint(10) UNSIGNED NOT NULL,
  `username` varchar(20) NOT NULL,
  `user_name` varchar(20) NOT NULL,
  `password` varchar(60) NOT NULL,
  `role` tinyint(3) UNSIGNED NOT NULL COMMENT '1=student, 2=approver, 3=staff'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`user_id`, `username`, `user_name`, `password`, `role`) VALUES
(1, 'joey', 'joey', '$2b$10$v0pJQO733/zEEGRl./6T9uKM3xSAxXqzP7d6FQKFvgtLaYEYMWqei', 1),
(9, 'staff', 'staff', '$2b$10$zeBME.vjcEaO1ucN7UV2xO3mrwadEoQGi.7xNJfgnDvXhEEdieoD.', 3),
(10, 'jonah', 'jonah', '$2b$10$EM4fuarDfkd8aK2XMBuuqehP86.1XwpE7TiuSzo4PlN9rJfeOp4SW', 3),
(11, 'johnny', 'johnny', '$2b$10$Mi21aS/e7sjoiKS7zi9tn.izaSHFHJhQmdWvCH5h21alZDq.avhKa', 2),
(12, 'tee', 'tee', '$2b$10$LJ8sHY2FsqJ3gxd0rF9REe6GP2Zyc2gLnrIzNrQwWeudcd3qEofKi', 1),
(13, 'app', 'app', '$2b$10$396X74INAGA8UeDVCTmmxOMiqj7Z60M3QtMIyd0xBFlofDxrisxby', 2),
(14, 'stu', 'stu', '$2b$10$02NPPqIwsMA2uSZb6YKxiu90EwO9CD0zE.tBfWs.WatFAv6JVTsW6', 1);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `information`
--
ALTER TABLE `information`
  ADD PRIMARY KEY (`id`),
  ADD KEY `approved by` (`approved_by`),
  ADD KEY `borrowed by` (`borrowed_by`),
  ADD KEY `roomID` (`room_id`);

--
-- Indexes for table `room`
--
ALTER TABLE `room`
  ADD PRIMARY KEY (`room_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`user_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `information`
--
ALTER TABLE `information`
  MODIFY `id` tinyint(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=38;

--
-- AUTO_INCREMENT for table `room`
--
ALTER TABLE `room`
  MODIFY `room_id` tinyint(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `user_id` tinyint(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `information`
--
ALTER TABLE `information`
  ADD CONSTRAINT `information_ibfk_1` FOREIGN KEY (`approved_by`) REFERENCES `users` (`user_id`),
  ADD CONSTRAINT `information_ibfk_2` FOREIGN KEY (`borrowed_by`) REFERENCES `users` (`user_id`),
  ADD CONSTRAINT `information_ibfk_3` FOREIGN KEY (`room_id`) REFERENCES `room` (`room_id`);

DELIMITER $$
--
-- Events
--
CREATE DEFINER=`root`@`localhost` EVENT `disable_slot_2` ON SCHEDULE EVERY 1 DAY STARTS '2024-11-12 12:00:00' ON COMPLETION NOT PRESERVE ENABLE DO UPDATE room SET slot_2 = 'disable' WHERE slot_2 != 'disable'$$

CREATE DEFINER=`root`@`localhost` EVENT `disable_slot_3` ON SCHEDULE EVERY 1 DAY STARTS '2024-11-12 15:00:00' ON COMPLETION NOT PRESERVE ENABLE DO UPDATE room SET slot_3 = 'disable' WHERE slot_3 != 'disable'$$

CREATE DEFINER=`root`@`localhost` EVENT `disable_slot_4` ON SCHEDULE EVERY 1 DAY STARTS '2024-11-12 17:00:00' ON COMPLETION NOT PRESERVE ENABLE DO UPDATE room SET slot_4 = 'disable' WHERE slot_4 != 'disable'$$

DELIMITER ;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
