<?php
// get_villes.php - Récupération de la liste des villes

require_once 'db_connection.php';

header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(["message" => "Méthode non autorisée. Seules les requêtes GET sont acceptées."]);
    exit();
}

try {
    // Récupérer toutes les villes actives
    $query = "SELECT id, nom, code_postal, latitude, longitude, is_active 
              FROM villes 
              WHERE is_active = 1 
              ORDER BY nom ASC";
    
    $result = $conn->query($query);
    
    if ($result === false) {
        throw new Exception("Erreur lors de la récupération des villes: " . $conn->error);
    }
    
    $villes = [];
    while ($row = $result->fetch_assoc()) {
        $villes[] = [
            'id' => (int)$row['id'],
            'nom' => $row['nom'],
            'code_postal' => $row['code_postal'],
            'latitude' => $row['latitude'] ? (float)$row['latitude'] : null,
            'longitude' => $row['longitude'] ? (float)$row['longitude'] : null,
            'is_active' => (bool)$row['is_active']
        ];
    }
    
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'data' => $villes,
        'count' => count($villes)
    ], JSON_UNESCAPED_UNICODE);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
} finally {
    if (isset($conn)) {
        $conn->close();
    }
}
?>

