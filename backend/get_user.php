<?php
// get_user.php - Récupérer les informations d'un utilisateur

require_once 'db_connection.php';

header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    $firebase_uid = $_GET['firebase_uid'] ?? '';
    $email = $_GET['email'] ?? '';

    if (empty($firebase_uid) && empty($email)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'firebase_uid ou email requis']);
        exit();
    }

    if (!empty($firebase_uid)) {
        $query = "SELECT id, firebase_uid, email, nom, photo_url, statut, is_active, created_at, updated_at 
                  FROM utilisateurs WHERE firebase_uid = ?";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("s", $firebase_uid);
    } else {
        // 💡 Recherche par email (insensible à la casse)
        $query = "SELECT id, firebase_uid, email, nom, photo_url, statut, is_active, created_at, updated_at 
                  FROM utilisateurs WHERE LOWER(email) = LOWER(?)";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("s", $email);
    }

    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $user = $result->fetch_assoc();
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'user' => $user
        ]);
    } else {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Utilisateur non trouvé'
        ]);
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

