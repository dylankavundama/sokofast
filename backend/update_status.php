<?php
header("Content-Type: application/json");
require_once 'db_connection.php';

try {
    // Récupère toutes les valeurs distinctes du champ `status`
    $stmt = $pdo->query("SELECT DISTINCT status FROM commandes ORDER BY status ASC");
    $statuses = $stmt->fetchAll(PDO::FETCH_COLUMN);

    echo json_encode([
        'success' => true,
        'statuses' => $statuses
    ]);
} catch (PDOException $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Erreur de base de données: ' . $e->getMessage()
    ]);
}
?>
