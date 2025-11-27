<?php
// get_note_livreur.php - Récupérer la note d'un livreur pour une commande

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'db_connection.php';
$conn->set_charset("utf8mb4");

$transaction_id = $_GET['transaction_id'] ?? '';
$client_name = $_GET['client_name'] ?? '';

if (empty($transaction_id) || empty($client_name)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'transaction_id et client_name sont requis'
    ]);
    exit();
}

try {
    $query = "SELECT note, commentaire, created_at 
              FROM notes_livreurs 
              WHERE transaction_id = ? AND client_name = ?
              LIMIT 1";
    $stmt = $conn->prepare($query);
    $stmt->bind_param("ss", $transaction_id, $client_name);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $note = $result->fetch_assoc();
        echo json_encode([
            'success' => true,
            'has_note' => true,
            'note' => $note
        ]);
    } else {
        echo json_encode([
            'success' => true,
            'has_note' => false
        ]);
    }
    
    $stmt->close();
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erreur serveur: ' . $e->getMessage()
    ]);
}

$conn->close();
?>

