-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Hôte : localhost:3306
-- Généré le : jeu. 27 nov. 2025 à 10:42
-- Version du serveur : 10.11.10-MariaDB-cll-lve
-- Version de PHP : 8.4.14

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de données : `tcnasblo_soko`
--

-- --------------------------------------------------------

--
-- Structure de la table `commandes`
--

CREATE TABLE `commandes` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `address` text NOT NULL,
  `ville_id` int(11) DEFAULT NULL,
  `livreur_id` int(11) DEFAULT NULL,
  `transaction_id` varchar(255) NOT NULL,
  `order_date` timestamp NOT NULL DEFAULT current_timestamp(),
  `product_name` varchar(255) NOT NULL,
  `quantity` int(11) NOT NULL,
  `payment_method` varchar(50) NOT NULL,
  `total_price` decimal(10,2) NOT NULL,
  `status` enum('annuler','en cours','terminer') DEFAULT 'en cours',
  `latitude` decimal(10,8) DEFAULT NULL,
  `longitude` decimal(11,8) DEFAULT NULL,
  `attribution_date` timestamp NULL DEFAULT NULL COMMENT 'Date d''attribution au livreur'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `commandes`
--

INSERT INTO `commandes` (`id`, `name`, `address`, `ville_id`, `livreur_id`, `transaction_id`, `order_date`, `product_name`, `quantity`, `payment_method`, `total_price`, `status`, `latitude`, `longitude`, `attribution_date`) VALUES
(159, 'gayux app', 'hhh', 3, NULL, 'SOKO-1764233576832', '2025-11-27 08:52:59', 'Amazon Echo (4e génération) avec son premium, hub domotique et Alexa - Blanc glacier', 1, 'FlexPay :243857478927', 100.00, 'en cours', -1.67748830, 29.24746120, NULL);

-- --------------------------------------------------------

--
-- Structure de la table `comments`
--

CREATE TABLE `comments` (
  `id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `user_name` varchar(100) NOT NULL,
  `comment` text NOT NULL,
  `rating` int(11) NOT NULL CHECK (`rating` >= 1 and `rating` <= 5),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Structure de la table `livreurs`
--

CREATE TABLE `livreurs` (
  `id` int(11) NOT NULL,
  `nom` varchar(100) NOT NULL,
  `prenom` varchar(100) NOT NULL,
  `telephone` varchar(20) NOT NULL,
  `email` varchar(255) DEFAULT NULL,
  `firebase_uid` varchar(255) DEFAULT NULL COMMENT 'ID Firebase de l''utilisateur livreur',
  `is_active` tinyint(1) DEFAULT 1,
  `is_available` tinyint(1) DEFAULT 1,
  `nombre_commandes_actuelles` int(11) DEFAULT 0,
  `note_moyenne` decimal(3,2) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `livreurs`
--

INSERT INTO `livreurs` (`id`, `nom`, `prenom`, `telephone`, `email`, `firebase_uid`, `is_active`, `is_available`, `nombre_commandes_actuelles`, `note_moyenne`, `created_at`, `updated_at`) VALUES
(12, 'kavundama', 'dylan', '0977734735', 'dylankavundama@gmail.com', NULL, 1, 1, 3, NULL, '2025-11-09 10:05:41', '2025-11-27 07:56:20');

-- --------------------------------------------------------

--
-- Structure de la table `notes_livreurs`
--

CREATE TABLE `notes_livreurs` (
  `id` int(11) NOT NULL,
  `commande_id` int(11) NOT NULL,
  `transaction_id` varchar(255) NOT NULL,
  `livreur_id` int(11) NOT NULL,
  `client_name` varchar(255) NOT NULL,
  `note` int(11) NOT NULL CHECK (`note` >= 1 and `note` <= 5),
  `commentaire` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déclencheurs `notes_livreurs`
--
DELIMITER $$
CREATE TRIGGER `update_note_moyenne_livreur` AFTER INSERT ON `notes_livreurs` FOR EACH ROW BEGIN
    UPDATE livreurs
    SET note_moyenne = (
        SELECT AVG(note)
        FROM notes_livreurs
        WHERE livreur_id = NEW.livreur_id
    )
    WHERE id = NEW.livreur_id;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `users`
--

INSERT INTO `users` (`id`, `email`, `password`, `created_at`) VALUES
(2, 'admin@babu.com', '$2y$10$.hN0druerHkQgnlUXPPOV.z5fzXtT3WA9M5wxCoXz1JjbUvW36o7K', '2025-07-12 18:10:08');

-- --------------------------------------------------------

--
-- Structure de la table `utilisateurs`
--

CREATE TABLE `utilisateurs` (
  `id` int(11) NOT NULL,
  `firebase_uid` varchar(255) NOT NULL COMMENT 'ID Firebase de l''utilisateur',
  `email` varchar(255) NOT NULL,
  `nom` varchar(255) DEFAULT NULL,
  `photo_url` text DEFAULT NULL,
  `statut` enum('client','vendeur') NOT NULL DEFAULT 'client' COMMENT 'Statut de l''utilisateur',
  `is_active` tinyint(1) NOT NULL DEFAULT 1 COMMENT 'Compte actif ou non',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table des utilisateurs de l''application';

--
-- Déchargement des données de la table `utilisateurs`
--

INSERT INTO `utilisateurs` (`id`, `firebase_uid`, `email`, `nom`, `photo_url`, `statut`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'sfaftxPtRsai93Yre2OWfbsvX842', 'vangimoise01@gmail.com', 'Moise Vangi0', 'https://lh3.googleusercontent.com/a/ACg8ocJhb6WmVIK5726NowX0-b56AzWoaP4ReodGepS9LwPkooxVTxA=s96-c', 'vendeur', 1, '2025-11-09 09:38:46', '2025-11-09 10:53:02'),
(2, 'VfniX7rlclaiysQuM1IXZxBvA9z1', 'dylankavundama@gmail.com', 'Dylan Kavundama', 'https://lh3.googleusercontent.com/a/ACg8ocI1Sk_HMluX_TDOzij28wPvpZHdaX3OcwKSu1LHf0bWGeM=s96-c', 'vendeur', 1, '2025-11-09 10:04:46', '2025-11-22 09:28:29'),
(3, '6KRrPIRWjJYiZjM070ohRJ3Q7mq2', 'junibarutiasnath@gmail.com', 'asnath juni baruti', 'https://lh3.googleusercontent.com/a/ACg8ocJTKakTrPfsn-x9EAypFhtR9W2vrSd3rWQUo7y5Ae9RVBCj_X4=s96-c', 'client', 1, '2025-11-09 10:28:58', '2025-11-09 12:12:35'),
(4, 'q3htiMg659PCorp21CFkaoQASsY2', 'gayuxapp@gmail.com', 'gayux app', 'https://lh3.googleusercontent.com/a/ACg8ocIcXqKbPARud-M1A_vIekPfWW18Vl0UYSJkYrFIUoHPVFxLpF4=s96-c', 'vendeur', 1, '2025-11-09 10:32:28', '2025-11-19 08:52:46'),
(5, 'fpFvBylGkkVJAHns8MfUwKdOW7m2', 'tcnasblog@gmail.com', 'tcn blog', 'https://lh3.googleusercontent.com/a/ACg8ocJ2L1ub6gYNMS9PF1atnDSvjXvh_67LtQp_m0NUzHIjMg=s96-c', 'client', 1, '2025-11-09 11:09:52', '2025-11-09 11:47:16'),
(6, 'i5wKoVPTCTP08GAp2AA4qIvuNTB3', 'raymondstevenson.67312@gmail.com', 'Raymond Stevenson', 'https://lh3.googleusercontent.com/a/ACg8ocIB1jKprmsBoNZ5MONEHffM_SdDSj0tzS6Bwd61DoAZ_dfP1Q=s96-c', 'client', 1, '2025-11-13 15:01:24', '2025-11-13 15:01:24'),
(7, 'DzmVLPlbRiMEh15nlq1icEz89v73', 'xxg3h3iqsd6ot5me6gvrrt-lvl-00@cloudtestlabaccounts.com', 'Nuage Laboratoire', 'https://lh3.googleusercontent.com/a/ACg8ocKwyxQXqduO9WrM1UpnIWoUUynhkGd6s8EUCH07Izp_h3DOkQ=s96-c', 'client', 1, '2025-11-13 15:14:50', '2025-11-13 15:14:50'),
(8, 'kz6CveEuUDQniGucoFh4CqTRr4B3', 'kheprilabs@gmail.com', 'Khepri Labs', 'https://lh3.googleusercontent.com/a/ACg8ocI4ML4sucvRPoMb1ihpB-cY8gH_WtsytoucocsEZTPFg7RzzBw=s96-c', 'vendeur', 1, '2025-11-16 22:39:30', '2025-11-20 10:18:03'),
(9, 'zlDAAWoZ25W6MzPBeepc6b8PtxB3', 'lyadungamigaboprudent@gmail.com', '', '', 'vendeur', 1, '2025-11-19 09:54:16', '2025-11-21 20:42:39'),
(10, 'N9YlcnqvgtgRJxOKFROBlhwElPx1', 'patnesskibizi@gmail.com', 'Patness Kibizi Tv', 'https://lh3.googleusercontent.com/a/ACg8ocI5274jYvXAW7gdjgnmRPQE8graJokcm2fYSWx7xmHV=s96-c', 'vendeur', 1, '2025-11-22 08:07:14', '2025-11-22 08:13:47'),
(11, 'Ms1ZfSwKPjOHI6RnDLgv7Weprkl1', 'lamarcarlson.64034@gmail.com', 'Lamar Carlson', 'https://lh3.googleusercontent.com/a/ACg8ocLXsqx-72q9N08SmCTGuEsR3009qI3788de65-_3ZKQcU5vcQ=s96-c', 'client', 1, '2025-11-22 08:46:14', '2025-11-22 08:47:13'),
(12, 'Wa624UHAf0McolM1lM7NRMtNvEz1', 'lucyfarmer.33360@gmail.com', 'Lucy Farmer', 'https://lh3.googleusercontent.com/a/ACg8ocJVHc4Nr98YjAhxqXYQUTwcAcIEu2UvkmV1UkxLV5-BBxIcLQ=s96-c', 'client', 1, '2025-11-22 08:48:31', '2025-11-22 08:49:00'),
(13, '3IRSzl9peCYsvbFXEc7u6uylt713', 'jtjoelk@gmail.com', 'joel jt', 'https://lh3.googleusercontent.com/a/ACg8ocJPjfOM_0qbaLU1-mTR1nCrevuiaQZBSsDcrI3XOyxv7lrRlMM=s96-c', 'vendeur', 1, '2025-11-22 10:02:14', '2025-11-24 16:54:53'),
(14, 's5DLOtJIFpc9d0MB2KvjvnpJcdN2', 'lussacogie1@gmail.com', 'Lussac Lussac', 'https://lh3.googleusercontent.com/a/ACg8ocK6-VDurOCoALK1bhlaoSnCTLkfULDQaskgpsnlIAFbutvW5gCG=s96-c', 'client', 1, '2025-11-23 06:33:41', '2025-11-23 06:33:41'),
(15, 'daWHg2Qnt2SzaoQHH0l3GT0cXmp2', 'jeannotnzanzum@gmail.com', 'Jeannot Nzanzu Muhindo', 'https://lh3.googleusercontent.com/a/ACg8ocJ7mAOZ9A18jFjTT0JHoePvxUk2i60x6QMUgQkfR5JY4MMK9z9T=s96-c', 'client', 1, '2025-11-24 08:21:50', '2025-11-24 08:21:50'),
(16, 'Fp6uWZn5PjOJgxdm6RsXhoycHXG2', 'jorgemitchell.12271@gmail.com', 'Jorge Mitchell', 'https://lh3.googleusercontent.com/a/ACg8ocIiqGGzYEfGtotPHovxK2UROUaa5xacvYVWpjokkC028REkZw=s96-c', 'client', 1, '2025-11-24 11:31:30', '2025-11-24 11:31:30'),
(17, 'WAUSsrgT8gSxjJUNxtBcH8Rs0B92', 'metafortenberry.96103@gmail.com', 'Meta Fortenberry', 'https://lh3.googleusercontent.com/a/ACg8ocKfVKSnp5cIXSY41wSGbbwuEkirW38CudkVYyFjTybqorJ1VQ=s96-c', 'client', 1, '2025-11-24 12:26:11', '2025-11-24 12:26:52'),
(18, 'Ih8z5fKamUcvJZA2Uv3qIyaexb63', 'samychristoph@gmail.com', 'Samy Christoph', 'https://lh3.googleusercontent.com/a/ACg8ocL5-q4z4D2cxw8fPmnaVA8nG-BaIJbSYpAvkwdptbVwfl4NP8Qu=s96-c', 'vendeur', 1, '2025-11-24 16:59:23', '2025-11-24 17:00:19'),
(19, '58BnuDHn6TfaV25whTxkvRZPhG83', 'btcdurba@gmail.com', 'Bureautique TechnicalCare', 'https://lh3.googleusercontent.com/a/ACg8ocI4xD61xZU5XNdjSgJ1RhfVYua9ay0CIzA1DetfXnQGt6_Gom4=s96-c', 'client', 1, '2025-11-24 17:07:38', '2025-11-24 17:10:17'),
(20, 'xBig8gjHT1Oihh5YAQzPCjFKIN43', 'b6mhs7vw8b@privaterelay.appleid.com', '', '', 'client', 1, '2025-11-25 17:21:06', '2025-11-25 17:21:06'),
(22, 'gnDllge582U8Xg9pbHbBVIMGWBj2', 'karmakatoro@gmail.com', 'Karma Katoro', 'https://lh3.googleusercontent.com/a/ACg8ocIMKbSXcMZfXl2K5vWAOZq06BttgHNKpgEpemLZSbs5_KukyM59=s96-c', 'client', 1, '2025-11-27 06:03:53', '2025-11-27 06:03:53');

-- --------------------------------------------------------

--
-- Structure de la table `villes`
--

CREATE TABLE `villes` (
  `id` int(11) NOT NULL,
  `nom` varchar(100) NOT NULL,
  `code_postal` varchar(20) DEFAULT NULL,
  `latitude` decimal(10,8) DEFAULT NULL,
  `longitude` decimal(11,8) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `villes`
--

INSERT INTO `villes` (`id`, `nom`, `code_postal`, `latitude`, `longitude`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'Kinshasa', '001', -4.32760000, 15.31360000, 1, '2025-11-09 09:09:04', NULL),
(2, 'Lubumbashi', '002', -11.66420000, 27.48260000, 1, '2025-11-09 09:09:04', NULL),
(3, 'Goma', '003', -1.67920000, 29.22280000, 1, '2025-11-09 09:09:04', NULL),
(4, 'Bukavu', '004', -2.50830000, 28.87250000, 1, '2025-11-09 09:09:04', NULL),
(5, 'Kisangani', '005', 0.51530000, 25.19100000, 1, '2025-11-09 09:09:04', NULL),
(6, 'Mbuji-Mayi', '006', -6.13600000, 23.59670000, 1, '2025-11-09 09:09:04', NULL),
(7, 'Kananga', '007', -5.89620000, 22.41660000, 1, '2025-11-09 09:09:04', NULL),
(8, 'Matadi', '008', -5.81670000, 13.45000000, 1, '2025-11-09 09:09:04', NULL),
(9, 'Kikwit', '009', -5.04000000, 18.81670000, 1, '2025-11-09 09:09:04', NULL),
(10, 'Uvira', '010', -3.39530000, 29.13780000, 1, '2025-11-09 09:09:04', NULL),
(11, 'okoko', '', NULL, NULL, 1, '2025-11-09 11:29:53', NULL);

-- --------------------------------------------------------

--
-- Structure de la table `ville_livreur`
--

CREATE TABLE `ville_livreur` (
  `id` int(11) NOT NULL,
  `ville_id` int(11) NOT NULL,
  `livreur_id` int(11) NOT NULL,
  `is_primary` tinyint(1) DEFAULT 0 COMMENT 'Livreur principal pour cette ville',
  `is_active` tinyint(1) DEFAULT 1 COMMENT 'Association active ou non',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Index pour les tables déchargées
--

--
-- Index pour la table `commandes`
--
ALTER TABLE `commandes`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_commande_ville` (`ville_id`),
  ADD KEY `fk_commande_livreur` (`livreur_id`);

--
-- Index pour la table `comments`
--
ALTER TABLE `comments`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `livreurs`
--
ALTER TABLE `livreurs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `telephone_unique` (`telephone`),
  ADD UNIQUE KEY `firebase_uid` (`firebase_uid`),
  ADD KEY `idx_is_active` (`is_active`),
  ADD KEY `idx_is_available` (`is_available`),
  ADD KEY `idx_firebase_uid` (`firebase_uid`);

--
-- Index pour la table `notes_livreurs`
--
ALTER TABLE `notes_livreurs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_commande_note` (`transaction_id`,`client_name`),
  ADD KEY `idx_livreur_id` (`livreur_id`),
  ADD KEY `idx_transaction_id` (`transaction_id`),
  ADD KEY `idx_commande_id` (`commande_id`);

--
-- Index pour la table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Index pour la table `utilisateurs`
--
ALTER TABLE `utilisateurs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `firebase_uid` (`firebase_uid`),
  ADD UNIQUE KEY `unique_firebase_uid` (`firebase_uid`),
  ADD UNIQUE KEY `unique_email` (`email`),
  ADD KEY `idx_statut` (`statut`),
  ADD KEY `idx_email` (`email`);

--
-- Index pour la table `villes`
--
ALTER TABLE `villes`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `nom_unique` (`nom`),
  ADD KEY `idx_is_active` (`is_active`);

--
-- Index pour la table `ville_livreur`
--
ALTER TABLE `ville_livreur`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `ville_livreur_unique` (`ville_id`,`livreur_id`),
  ADD KEY `fk_ville` (`ville_id`),
  ADD KEY `fk_livreur` (`livreur_id`),
  ADD KEY `idx_is_active` (`is_active`);

--
-- AUTO_INCREMENT pour les tables déchargées
--

--
-- AUTO_INCREMENT pour la table `commandes`
--
ALTER TABLE `commandes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=160;

--
-- AUTO_INCREMENT pour la table `comments`
--
ALTER TABLE `comments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=71;

--
-- AUTO_INCREMENT pour la table `livreurs`
--
ALTER TABLE `livreurs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT pour la table `notes_livreurs`
--
ALTER TABLE `notes_livreurs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT pour la table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT pour la table `utilisateurs`
--
ALTER TABLE `utilisateurs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

--
-- AUTO_INCREMENT pour la table `villes`
--
ALTER TABLE `villes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT pour la table `ville_livreur`
--
ALTER TABLE `ville_livreur`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

--
-- Contraintes pour les tables déchargées
--

--
-- Contraintes pour la table `commandes`
--
ALTER TABLE `commandes`
  ADD CONSTRAINT `fk_commande_livreur` FOREIGN KEY (`livreur_id`) REFERENCES `livreurs` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_commande_ville` FOREIGN KEY (`ville_id`) REFERENCES `villes` (`id`) ON DELETE SET NULL;

--
-- Contraintes pour la table `notes_livreurs`
--
ALTER TABLE `notes_livreurs`
  ADD CONSTRAINT `notes_livreurs_ibfk_1` FOREIGN KEY (`livreur_id`) REFERENCES `livreurs` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `ville_livreur`
--
ALTER TABLE `ville_livreur`
  ADD CONSTRAINT `fk_ville_livreur_livreur` FOREIGN KEY (`livreur_id`) REFERENCES `livreurs` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_ville_livreur_ville` FOREIGN KEY (`ville_id`) REFERENCES `villes` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
