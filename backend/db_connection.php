<?php
/**
 * Configuration centralisée de la base de données
 * Ce fichier doit être inclus dans tous les fichiers PHP qui nécessitent une connexion à la base de données
 */

// Configuration de la base de données
define('DB_HOST', 'localhost');
define('DB_NAME', 'tcnasblo_soko');
define('DB_USER', 'tcnasblo_soko');
define('DB_PASS', 'hOpFh*B,r&@@N&&w');

// Variables pour compatibilité avec l'ancien code
$host = DB_HOST;
$dbname = DB_NAME;
$user = DB_USER;
$pass = DB_PASS;

// Variables avec noms alternatifs pour compatibilité
$servername = DB_HOST;
$username = DB_USER;
$password = DB_PASS;

// Connexion MySQLi (pour la plupart des fichiers)
$conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);

if ($conn->connect_error) {
    // Si on est dans un contexte API, retourner JSON
    if (isset($_SERVER['HTTP_ACCEPT']) && strpos($_SERVER['HTTP_ACCEPT'], 'application/json') !== false) {
        header('Content-Type: application/json');
        http_response_code(500);
        die(json_encode([
            'success' => false,
            'message' => 'Erreur de connexion à la base de données : ' . $conn->connect_error
        ]));
    } else {
        // Sinon, afficher une erreur simple
        die('Erreur de connexion à la base de données : ' . $conn->connect_error);
    }
}

// Définir le charset UTF-8
$conn->set_charset("utf8mb4");

// Connexion PDO (pour les fichiers qui utilisent PDO comme getcmd.php)
try {
    $pdo = new PDO(
        "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4",
        DB_USER,
        DB_PASS,
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false
        ]
    );
} catch (PDOException $e) {
    // Si on est dans un contexte API, retourner JSON
    if (isset($_SERVER['HTTP_ACCEPT']) && strpos($_SERVER['HTTP_ACCEPT'], 'application/json') !== false) {
        header('Content-Type: application/json');
        http_response_code(500);
        die(json_encode([
            'success' => false,
            'message' => 'Erreur de connexion PDO à la base de données : ' . $e->getMessage()
        ]));
    } else {
        die('Erreur de connexion PDO à la base de données : ' . $e->getMessage());
    }
}
?>
