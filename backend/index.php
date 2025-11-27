<?php
// index.php

session_start(); // Démarre la session PHP en tout premier

// Initialisation des variables pour la vue
$message = '';
$error = '';
$result = null;
$pending_orders = 0;

// --- 1. Vérification de la Connexion et Redirection ---
if (!isset($_SESSION['loggedin']) || $_SESSION['loggedin'] !== true) {
    header('Location: login.php'); // Redirige vers la page de connexion
    exit;
}

// --- 2. Gestion de la Déconnexion ---
if (isset($_GET['action']) && $_GET['action'] === 'logout') {
    session_unset(); // Supprime toutes les variables de session
    session_destroy(); // Détruit la session
    header('Location: login.php'); // Redirige vers la page de connexion
    exit;
}

// --- 3. Connexion à la base de données ---
// Le fichier 'db_connection.php' est censé initialiser la variable $conn
require_once 'db_connection.php';

if (!isset($conn) || $conn->connect_error) {
    error_log("Failed to connect to database: " . ($conn->connect_error ?? 'Error undefined')); // Log l'erreur
    $error = "Erreur fatale : Impossible de se connecter à la base de données.";
    // Ne pas exit ici pour afficher au moins l'erreur, mais éviter les opérations DB
} else {
    $conn->set_charset("utf8mb4");

    // --- 4. Traitement de la modification de statut (POST) ---
    if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['update_status'])) {
        // Vérification du jeton CSRF
        if (!isset($_POST['csrf_token']) || $_POST['csrf_token'] !== ($_SESSION['csrf_token'] ?? '')) {
            $error = "Erreur de sécurité : Jeton CSRF invalide.";
        } else {
            // Validation et assainissement des entrées
            $id = filter_input(INPUT_POST, 'id', FILTER_VALIDATE_INT);
            $new_status = filter_input(INPUT_POST, 'new_status', FILTER_SANITIZE_STRING);

            // Define valid statuses. These MUST EXACTLY match your ENUM values.
            $valid_statuses = ['annuler', 'en cours', 'terminer'];

            if ($id === false || $id === null) {
                $error = "ID de commande invalide.";
            } elseif (!in_array($new_status, $valid_statuses)) {
                $error = "Statut invalide. Veuillez choisir parmi : " . implode(', ', $valid_statuses);
            } else {
                $stmt = $conn->prepare("UPDATE commandes SET status = ? WHERE id = ?");

                if ($stmt === false) {
                    $error = "Erreur de préparation de la requête : " . $conn->error;
                } else {
                    $stmt->bind_param("si", $new_status, $id);
                    if ($stmt->execute()) {
                        $success_msg = "Le statut de la commande #{$id} a été mis à jour avec succès à '{$new_status}'.";
                        // Post-Redirect-Get (PRG) pattern
                        header("Location: " . $_SERVER['PHP_SELF'] . "?message=" . urlencode($success_msg));
                        exit();
                    } else {
                        $error = "Une erreur est survenue lors de la mise à jour du statut : " . $stmt->error;
                    }
                    $stmt->close();
                }
            }
        }
    }

    // --- 5. Récupération des Commandes ---
    // Ajout des champs 'address', 'transaction_id', 'latitude', 'longitude' pour la vue détaillée (si nécessaire)
    $query = "SELECT id, name, address, transaction_id, product_name, quantity, total_price, status, payment_method, order_date FROM commandes ORDER BY order_date DESC";
    $result = $conn->query($query);

    if ($result === false) {
        $error = "Erreur lors de la récupération des commandes : " . $conn->error;
        $result = null; // S'assurer que $result est null si la requête échoue
    }

    // --- 6. Comptage des commandes en cours pour le badge (Doit se faire APRÈS la connexion) ---
    $stmt_count_orders = $conn->prepare("SELECT COUNT(*) AS total_pending FROM commandes WHERE status = 'en cours'");
    if ($stmt_count_orders) {
        $stmt_count_orders->execute();
        $result_count_orders = $stmt_count_orders->get_result();
        $pending_orders = $result_count_orders->fetch_assoc()['total_pending'] ?? 0;
        $stmt_count_orders->close();
    }
}


// --- 7. Gestion des Messages (GET) et Jeton CSRF ---

// Récupération des messages de redirection
if (isset($_GET['message'])) {
    $message = htmlspecialchars($_GET['message']);
}
if (isset($_GET['error'])) {
    $error = htmlspecialchars($_GET['error']);
}

// Générer un jeton CSRF pour les formulaires (si non déjà défini)
if (empty($_SESSION['csrf_token'])) {
    $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
}

// Récupérer le nom d'utilisateur pour l'affichage (sécurité)
if (!isset($_SESSION['username'])) {
    $_SESSION['username'] = 'Admin'; // Valeur par défaut si non définie
}

// --- 8. Redirection vers le nouveau système de gestion ---
// Redirection vers le nouveau système de gestion complet
header('Location: systeme_gestion.php');
exit;

// --- 9. Fermeture de la connexion DB ---
if (isset($conn) && $conn instanceof mysqli) {
    $conn->close();
}