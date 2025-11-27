<?php
// gestion_livreurs.php - Interface de gestion des livreurs et attributions

require_once 'db_connection.php';

header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? '';

try {
    switch ($method) {
        case 'GET':
            if ($action === 'commandes_sans_livreur') {
                // Récupérer les commandes sans livreur attribué
                $query = "SELECT c.id, c.name, c.address, c.transaction_id, c.product_name, 
                                 c.quantity, c.total_price, c.status, c.order_date,
                                 v.id as ville_id, v.nom as ville_nom
                          FROM commandes c
                          LEFT JOIN villes v ON c.ville_id = v.id
                          WHERE c.livreur_id IS NULL AND c.status IN ('en cours', 'PENDING', 'EN_COURS')
                          ORDER BY c.order_date DESC
                          LIMIT 50";
                
                $result = $conn->query($query);
                $commandes = [];
                
                while ($row = $result->fetch_assoc()) {
                    $commandes[] = $row;
                }
                
                echo json_encode([
                    'success' => true,
                    'data' => $commandes,
                    'count' => count($commandes)
                ], JSON_UNESCAPED_UNICODE);
                
            } else if ($action === 'commandes_par_livreur') {
                // Récupérer les commandes d'un livreur spécifique
                $livreur_id = (int)($_GET['livreur_id'] ?? 0);
                
                if ($livreur_id <= 0) {
                    http_response_code(400);
                    echo json_encode(['success' => false, 'message' => 'livreur_id requis']);
                    exit();
                }
                
                $query = "SELECT c.id, c.name, c.address, c.transaction_id, c.product_name, 
                                 c.quantity, c.total_price, c.status, c.order_date,
                                 v.nom as ville_nom
                          FROM commandes c
                          LEFT JOIN villes v ON c.ville_id = v.id
                          WHERE c.livreur_id = ?
                          ORDER BY c.order_date DESC";
                
                $stmt = $conn->prepare($query);
                $stmt->bind_param("i", $livreur_id);
                $stmt->execute();
                $result = $stmt->get_result();
                
                $commandes = [];
                while ($row = $result->fetch_assoc()) {
                    $commandes[] = $row;
                }
                
                $stmt->close();
                
                echo json_encode([
                    'success' => true,
                    'data' => $commandes,
                    'count' => count($commandes)
                ], JSON_UNESCAPED_UNICODE);
                
            } else if ($action === 'statistiques') {
                // Statistiques des livreurs
                $query = "SELECT 
                            l.id, l.nom, l.prenom, l.telephone,
                            COUNT(c.id) as total_commandes,
                            SUM(CASE WHEN c.status IN ('TERMINER', 'CONFIRMED') THEN 1 ELSE 0 END) as commandes_terminees,
                            l.nombre_commandes_actuelles,
                            l.is_available,
                            GROUP_CONCAT(DISTINCT v.nom SEPARATOR ', ') as villes
                          FROM livreurs l
                          LEFT JOIN commandes c ON l.id = c.livreur_id
                          LEFT JOIN ville_livreur vl ON l.id = vl.livreur_id
                          LEFT JOIN villes v ON vl.ville_id = v.id
                          WHERE l.is_active = 1
                          GROUP BY l.id
                          ORDER BY l.nom ASC";
                
                $result = $conn->query($query);
                $stats = [];
                
                while ($row = $result->fetch_assoc()) {
                    $stats[] = [
                        'livreur_id' => (int)$row['id'],
                        'nom_complet' => $row['nom'] . ' ' . $row['prenom'],
                        'telephone' => $row['telephone'],
                        'total_commandes' => (int)$row['total_commandes'],
                        'commandes_terminees' => (int)$row['commandes_terminees'],
                        'commandes_actuelles' => (int)$row['nombre_commandes_actuelles'],
                        'is_available' => (bool)$row['is_available'],
                        'villes' => $row['villes']
                    ];
                }
                
                echo json_encode([
                    'success' => true,
                    'data' => $stats
                ], JSON_UNESCAPED_UNICODE);
                
            } else {
                http_response_code(400);
                echo json_encode(['success' => false, 'message' => 'Action non reconnue']);
            }
            break;
            
        case 'PUT':
            // Mettre à jour le statut d'un livreur (disponible/indisponible)
            $input_data = file_get_contents("php://input");
            $data = json_decode($input_data);
            
            if (!isset($data->livreur_id) || !isset($data->is_available)) {
                http_response_code(400);
                echo json_encode(['success' => false, 'message' => 'livreur_id et is_available requis']);
                exit();
            }
            
            $livreur_id = (int)$data->livreur_id;
            $is_available = (bool)$data->is_available ? 1 : 0;
            
            $query = "UPDATE livreurs SET is_available = ? WHERE id = ?";
            $stmt = $conn->prepare($query);
            $stmt->bind_param("ii", $is_available, $livreur_id);
            
            if ($stmt->execute()) {
                echo json_encode([
                    'success' => true,
                    'message' => 'Statut du livreur mis à jour'
                ]);
            } else {
                http_response_code(500);
                echo json_encode([
                    'success' => false,
                    'message' => 'Erreur lors de la mise à jour'
                ]);
            }
            
            $stmt->close();
            break;
            
        default:
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Méthode non autorisée']);
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
} finally {
    if (isset($conn)) {
        $conn->close();
    }
}
?>

