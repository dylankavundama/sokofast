<?php
// associer_ville_livreur.php - Associer ou dissocier un livreur à une ville

require_once 'db_connection.php';

header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$input_data = file_get_contents("php://input");
$data = json_decode($input_data);

if (!$data || !isset($data->ville_id) || !isset($data->livreur_id)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'ville_id et livreur_id sont requis']);
    exit();
}

$ville_id = (int)$data->ville_id;
$livreur_id = (int)$data->livreur_id;
$is_primary = isset($data->is_primary) ? (int)$data->is_primary : 0;
$action = $data->action ?? 'add'; // 'add' ou 'remove'

try {
    if ($action === 'remove') {
        // SUPPRESSION de l'association
        $query = "DELETE FROM ville_livreur WHERE ville_id = ? AND livreur_id = ?";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("ii", $ville_id, $livreur_id);
        
        if ($stmt->execute()) {
            http_response_code(200);
            echo json_encode([
                'success' => true,
                'message' => 'Association supprimée avec succès'
            ]);
        } else {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Erreur: ' . $stmt->error]);
        }
    } else {
        // AJOUT ou MODIFICATION de l'association
        // Si l'association existe déjà, on la met à jour
        $check_query = "SELECT id FROM ville_livreur WHERE ville_id = ? AND livreur_id = ?";
        $check_stmt = $conn->prepare($check_query);
        $check_stmt->bind_param("ii", $ville_id, $livreur_id);
        $check_stmt->execute();
        $exists = $check_stmt->get_result()->num_rows > 0;
        $check_stmt->close();

        if ($exists) {
            // Mise à jour (notamment pour changer is_primary)
            $query = "UPDATE ville_livreur SET is_primary = ? WHERE ville_id = ? AND livreur_id = ?";
            $stmt = $conn->prepare($query);
            $stmt->bind_param("iii", $is_primary, $ville_id, $livreur_id);
        } else {
            // Ajout
            $query = "INSERT INTO ville_livreur (ville_id, livreur_id, is_primary) VALUES (?, ?, ?)";
            $stmt = $conn->prepare($query);
            $stmt->bind_param("iii", $ville_id, $livreur_id, $is_primary);
        }

        if ($stmt->execute()) {
            http_response_code(200);
            echo json_encode([
                'success' => true,
                'message' => $exists ? 'Association modifiée avec succès' : 'Association créée avec succès'
            ]);
        } else {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Erreur: ' . $stmt->error]);
        }
    }

    if (isset($stmt)) {
        $stmt->close();
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
} finally {
    if (isset($conn)) {
        $conn->close();
    }
}
?>

