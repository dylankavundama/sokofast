<?php
// update_user_status.php - Mettre à jour le statut d'un utilisateur (admin seulement)

require_once 'db_connection.php';

header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, PUT, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$input_data = file_get_contents("php://input");
$data = json_decode($input_data);

if (!$data) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Données JSON invalides']);
    exit();
}

try {
    $firebase_uid = trim($data->firebase_uid ?? '');
    $statut = isset($data->statut) && in_array($data->statut, ['client', 'vendeur']) ? $data->statut : null;

    if (empty($firebase_uid) || $statut === null) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'firebase_uid et statut sont requis']);
        exit();
    }

    $query = "UPDATE utilisateurs SET statut = ?, updated_at = NOW() WHERE firebase_uid = ?";
    $stmt = $conn->prepare($query);
    $stmt->bind_param("ss", $statut, $firebase_uid);

    if ($stmt->execute()) {
        if ($stmt->affected_rows > 0) {
            http_response_code(200);
            echo json_encode([
                'success' => true,
                'message' => 'Statut mis à jour avec succès',
                'statut' => $statut
            ]);
        } else {
            http_response_code(404);
            echo json_encode([
                'success' => false,
                'message' => 'Utilisateur non trouvé'
            ]);
        }
    } else {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Erreur: ' . $stmt->error]);
    }

    $stmt->close();
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
} finally {
    if (isset($conn)) {
        $conn->close();
    }
}
?>

