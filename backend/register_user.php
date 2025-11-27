<?php
// register_user.php - Enregistrer ou mettre à jour un utilisateur

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
    $email = trim($data->email ?? '');
    $nom = trim($data->nom ?? '');
    $photo_url = trim($data->photo_url ?? '');
    $statut = isset($data->statut) && in_array($data->statut, ['client', 'vendeur']) ? $data->statut : 'client';

    if (empty($firebase_uid) || empty($email)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'firebase_uid et email sont requis']);
        exit();
    }

    // Vérifier si l'utilisateur existe déjà
    $check_query = "SELECT id, statut FROM utilisateurs WHERE firebase_uid = ? OR email = ?";
    $check_stmt = $conn->prepare($check_query);
    $check_stmt->bind_param("ss", $firebase_uid, $email);
    $check_stmt->execute();
    $check_result = $check_stmt->get_result();
    $existing_user = $check_result->fetch_assoc();
    $check_stmt->close();

    if ($existing_user) {
        // MISE À JOUR de l'utilisateur existant
        // 💡 Mettre à jour uniquement les champs qui peuvent changer (email, nom, photo_url)
        // Le statut est conservé pour permettre l'attribution manuelle par l'admin
        $update_query = "UPDATE utilisateurs SET email = ?, nom = ?, photo_url = ?, updated_at = NOW() WHERE id = ?";
        $update_stmt = $conn->prepare($update_query);
        $update_stmt->bind_param("sssi", $email, $nom, $photo_url, $existing_user['id']);
        
        if ($update_stmt->execute()) {
            http_response_code(200);
            echo json_encode([
                'success' => true,
                'message' => 'Utilisateur mis à jour avec succès',
                'user' => [
                    'id' => $existing_user['id'],
                    'firebase_uid' => $firebase_uid,
                    'email' => $email,
                    'nom' => $nom,
                    'statut' => $existing_user['statut'], // Conserver le statut existant (client/vendeur)
                    'photo_url' => $photo_url
                ]
            ]);
        } else {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Erreur lors de la mise à jour: ' . $update_stmt->error]);
        }
        $update_stmt->close();
    } else {
        // AJOUT d'un nouvel utilisateur
        $insert_query = "INSERT INTO utilisateurs (firebase_uid, email, nom, photo_url, statut) VALUES (?, ?, ?, ?, ?)";
        $insert_stmt = $conn->prepare($insert_query);
        $insert_stmt->bind_param("sssss", $firebase_uid, $email, $nom, $photo_url, $statut);
        
        if ($insert_stmt->execute()) {
            $new_id = $conn->insert_id;
            http_response_code(201);
            echo json_encode([
                'success' => true,
                'message' => 'Utilisateur enregistré avec succès',
                'user' => [
                    'id' => $new_id,
                    'firebase_uid' => $firebase_uid,
                    'email' => $email,
                    'nom' => $nom,
                    'statut' => $statut,
                    'photo_url' => $photo_url
                ]
            ]);
        } else {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Erreur lors de l\'enregistrement: ' . $insert_stmt->error]);
        }
        $insert_stmt->close();
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

