-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Nov 15, 2025 at 12:02 PM
-- Server version: 10.4.28-MariaDB
-- PHP Version: 8.1.17

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
  `id` tinyint(3) UNSIGNED NOT NULL,
  `user_id` tinyint(4) NOT NULL COMMENT 'ผู้จอง',
  `room_id` tinyint(3) UNSIGNED NOT NULL,
  `slot` enum('slot_1','slot_2','slot_3','slot_4') NOT NULL,
  `borrowed_by` tinyint(3) UNSIGNED NOT NULL,
  `borrowed_date` datetime NOT NULL DEFAULT current_timestamp(),
  `approved_by` tinyint(3) UNSIGNED DEFAULT NULL,
  `status` tinyint(2) NOT NULL DEFAULT 0 COMMENT '0=รออนุมัติ, 1=อนุมัติ, 2=ไม่อนุมัติ'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `information`
--

INSERT INTO `information` (`id`, `user_id`, `room_id`, `slot`, `borrowed_by`, `borrowed_date`, `approved_by`, `status`) VALUES
(3, 1, 1, 'slot_1', 1, '2025-10-03 10:22:41', 13, 1),
(4, 1, 2, 'slot_2', 1, '2025-10-03 10:39:27', 13, 1),
(5, 14, 1, 'slot_2', 14, '2025-10-07 15:58:38', 13, 1);

-- --------------------------------------------------------

--
-- Table structure for table `room`
--

CREATE TABLE `room` (
  `room_id` tinyint(3) UNSIGNED NOT NULL,
  `room_name` varchar(255) NOT NULL,
  `size` tinyint(1) NOT NULL COMMENT '1=S, 2=M, 3=L',
  `image` varchar(255) DEFAULT NULL,
  `slot_1` enum('free','pending','reserve','disable','full') NOT NULL DEFAULT 'free' COMMENT '08:00-10:00',
  `slot_2` enum('free','pending','reserve','disable','full') NOT NULL DEFAULT 'free' COMMENT '10:00-12:00',
  `slot_3` enum('free','pending','reserve','disable','full') NOT NULL DEFAULT 'free' COMMENT '13:00-15:00',
  `slot_4` enum('free','pending','reserve','disable','full') NOT NULL DEFAULT 'free' COMMENT '15:00-17:00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `room`
--

INSERT INTO `room` (`room_id`, `room_name`, `size`, `image`, `slot_1`, `slot_2`, `slot_3`, `slot_4`) VALUES
(1, 'S1 101', 3, 'large.jpeg', 'reserve', 'reserve', 'free', 'free'),
(2, 'S1 102', 1, 'small.jpeg', 'free', 'pending', 'free', 'disable'),
(3, 'S1 103', 1, 'small.jpeg', 'free', 'disable', 'free', 'free'),
(4, 'S1 104', 2, 'medium.jpeg', 'free', 'free', 'free', 'free'),
(6, 's1 301', 1, '1759827681983.jpg', 'free', 'free', 'free', 'free');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `user_id` tinyint(3) UNSIGNED NOT NULL,
  `username` varchar(20) NOT NULL,
  `user_name` varchar(20) NOT NULL,
  `password` varchar(60) NOT NULL,
  `role` tinyint(3) UNSIGNED NOT NULL COMMENT '1=student, 2=approver, 3=staff',
  `profile_image` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`user_id`, `username`, `user_name`, `password`, `role`, `profile_image`) VALUES
(1, 'James', 'James', '$2b$10$hC81BbYkkS7DwofWztl0sOymmAabsqjMERC69U1l.fnXvWFIFmMjm', 1, '1759329039199.jpg'),
(11, 'staff', 'staff', '$2b$10$Si6Y5EqgR.NwjsnkY1H8UOKR6DjmDIMyKrxB3qQZp0h/MRu3UeXGO', 3, NULL),
(13, 'approved', 'approved', '$2b$10$xeWaJLJ8NCLfN22KHs1hOO3dQQfUqMYfhIaSJgXVejc5G2tboxcPq', 2, NULL),
(14, 'I', 'hi', '$2b$10$pjl7k1sOg4CATswrP.TN1OKEAp60oM4SGSX0STRX8BlpaZGP1nkeK', 1, NULL);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `information`
--
ALTER TABLE `information`
  ADD PRIMARY KEY (`id`),
  ADD KEY `roomID` (`room_id`),
  ADD KEY `borrowed_by` (`borrowed_by`),
  ADD KEY `approved_by` (`approved_by`);

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
  MODIFY `id` tinyint(3) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `room`
--
ALTER TABLE `room`
  MODIFY `room_id` tinyint(3) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `user_id` tinyint(3) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `information`
--
ALTER TABLE `information`
  ADD CONSTRAINT `fk_information_approved_by` FOREIGN KEY (`approved_by`) REFERENCES `users` (`user_id`),
  ADD CONSTRAINT `fk_information_borrowed_by` FOREIGN KEY (`borrowed_by`) REFERENCES `users` (`user_id`),
  ADD CONSTRAINT `fk_information_room` FOREIGN KEY (`room_id`) REFERENCES `room` (`room_id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
