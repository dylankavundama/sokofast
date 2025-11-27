<?php
// check_livreur.php - Vérifier si un utilisateur Firebase est un livreur

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
        $query = "SELECT l.id, l.nom, l.prenom, l.telephone, l.email, 
                         l.is_active, l.is_available, l.nombre_commandes_actuelles,
                         l.note_moyenne, l.firebase_uid
                  FROM livreurs l
                  WHERE l.firebase_uid = ? AND l.is_active = 1";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("s", $firebase_uid);
    } else {
        // 💡 Recherche par email (insensible à la casse)
        $query = "SELECT l.id, l.nom, l.prenom, l.telephone, l.email, 
                         l.is_active, l.is_available, l.nombre_commandes_actuelles,
                         l.note_moyenne, l.firebase_uid
                  FROM livreurs l
                  WHERE LOWER(l.email) = LOWER(?) AND l.is_active = 1";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("s", $email);
    }

    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $livreur = $result->fetch_assoc();
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'is_livreur' => true,
            'livreur' => $livreur
        ]);
    } else {
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'is_livreur' => false,
            'message' => 'Utilisateur n\'est pas un livreur'
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

