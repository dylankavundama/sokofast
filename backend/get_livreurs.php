<?php
// get_livreurs.php - Récupération de la liste des livreurs

require_once 'db_connection.php';

header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Récupérer le paramètre ville_id si fourni
$ville_id = isset($_GET['ville_id']) ? (int)$_GET['ville_id'] : null;

try {
    if ($ville_id) {
        // Récupérer les livreurs pour une ville spécifique
        $query = "SELECT l.id, l.nom, l.prenom, l.telephone, l.email, 
                         l.is_active, l.is_available, l.nombre_commandes_actuelles,
                         l.note_moyenne, vl.is_primary
                  FROM livreurs l
                  INNER JOIN ville_livreur vl ON l.id = vl.livreur_id
                  WHERE vl.ville_id = ? AND l.is_active = 1
                  ORDER BY vl.is_primary DESC, l.nombre_commandes_actuelles ASC, l.nom ASC";
        
        $stmt = $conn->prepare($query);
        if ($stmt === false) {
            throw new Exception("Erreur de préparation: " . $conn->error);
        }
        
        $stmt->bind_param("i", $ville_id);
        $stmt->execute();
        $result = $stmt->get_result();
    } else {
        // Récupérer tous les livreurs actifs
        $query = "SELECT id, nom, prenom, telephone, email, 
                         is_active, is_available, nombre_commandes_actuelles, note_moyenne
                  FROM livreurs 
                  WHERE is_active = 1 
                  ORDER BY nom ASC";
        
        $result = $conn->query($query);
        if ($result === false) {
            throw new Exception("Erreur lors de la récupération: " . $conn->error);
        }
    }
    
    $livreurs = [];
    while ($row = $result->fetch_assoc()) {
        $livreurs[] = [
            'id' => (int)$row['id'],
            'nom' => $row['nom'],
            'prenom' => $row['prenom'],
            'nom_complet' => $row['nom'] . ' ' . $row['prenom'],
            'telephone' => $row['telephone'],
            'email' => $row['email'],
            'is_active' => (bool)$row['is_active'],
            'is_available' => (bool)$row['is_available'],
            'nombre_commandes_actuelles' => (int)$row['nombre_commandes_actuelles'],
            'note_moyenne' => $row['note_moyenne'] ? (float)$row['note_moyenne'] : null,
            'is_primary' => isset($row['is_primary']) ? (bool)$row['is_primary'] : null
        ];
    }
    
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'data' => $livreurs,
        'count' => count($livreurs)
    ], JSON_UNESCAPED_UNICODE);
    
    if (isset($stmt)) {
        $stmt->close();
    }
    
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

