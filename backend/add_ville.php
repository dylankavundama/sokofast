<?php
// add_ville.php - Ajouter ou modifier une ville

require_once 'db_connection.php';

header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, PUT, DELETE, OPTIONS");
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
    // 💡 NOUVEAU : Gestion de la suppression
    if (isset($data->action) && $data->action === 'delete') {
        $id = isset($data->id) ? (int)$data->id : null;
        
        if (!$id) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'ID de la ville requis pour la suppression']);
            exit();
        }
        
        // Vérifier s'il y a des commandes associées
        $check_commandes = $conn->prepare("SELECT COUNT(*) as total FROM commandes WHERE ville_id = ?");
        $check_commandes->bind_param("i", $id);
        $check_commandes->execute();
        $result_commandes = $check_commandes->get_result();
        $nb_commandes = $result_commandes->fetch_assoc()['total'];
        $check_commandes->close();
        
        if ($nb_commandes > 0) {
            // Soft delete : désactiver la ville au lieu de la supprimer
            $query = "UPDATE villes SET is_active = 0, updated_at = NOW() WHERE id = ?";
            $stmt = $conn->prepare($query);
            $stmt->bind_param("i", $id);
            
            if ($stmt->execute()) {
                // Désactiver aussi les associations ville-livreur
                $update_assoc = $conn->prepare("UPDATE ville_livreur SET is_active = 0 WHERE ville_id = ?");
                $update_assoc->bind_param("i", $id);
                $update_assoc->execute();
                $update_assoc->close();
                
                http_response_code(200);
                echo json_encode([
                    'success' => true,
                    'message' => 'Ville désactivée avec succès (des commandes y sont associées)',
                    'id' => $id
                ]);
            } else {
                http_response_code(500);
                echo json_encode(['success' => false, 'message' => 'Erreur lors de la désactivation: ' . $stmt->error]);
            }
            $stmt->close();
        } else {
            // Aucune commande associée : soft delete
            $query = "UPDATE villes SET is_active = 0, updated_at = NOW() WHERE id = ?";
            $stmt = $conn->prepare($query);
            $stmt->bind_param("i", $id);
            
            if ($stmt->execute()) {
                // Désactiver aussi les associations ville-livreur
                $update_assoc = $conn->prepare("UPDATE ville_livreur SET is_active = 0 WHERE ville_id = ?");
                $update_assoc->bind_param("i", $id);
                $update_assoc->execute();
                $update_assoc->close();
                
                http_response_code(200);
                echo json_encode([
                    'success' => true,
                    'message' => 'Ville supprimée avec succès',
                    'id' => $id
                ]);
            } else {
                http_response_code(500);
                echo json_encode(['success' => false, 'message' => 'Erreur lors de la suppression: ' . $stmt->error]);
            }
            $stmt->close();
        }
    } else {
        // AJOUT ou MODIFICATION (code existant)
        $nom = trim($data->nom ?? '');
        $code_postal = trim($data->code_postal ?? '');
        $latitude = isset($data->latitude) && is_numeric($data->latitude) ? (float)$data->latitude : null;
        $longitude = isset($data->longitude) && is_numeric($data->longitude) ? (float)$data->longitude : null;
        $is_active = isset($data->is_active) ? (int)$data->is_active : 1;
        $id = isset($data->id) ? (int)$data->id : null;

        if (empty($nom)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Le nom de la ville est requis']);
            exit();
        }

        if ($id) {
            // MODIFICATION
            $query = "UPDATE villes SET nom = ?, code_postal = ?, latitude = ?, longitude = ?, is_active = ?, updated_at = NOW() WHERE id = ?";
            $stmt = $conn->prepare($query);
            $stmt->bind_param("ssddii", $nom, $code_postal, $latitude, $longitude, $is_active, $id);
        } else {
            // AJOUT
            $query = "INSERT INTO villes (nom, code_postal, latitude, longitude, is_active) VALUES (?, ?, ?, ?, ?)";
            $stmt = $conn->prepare($query);
            $stmt->bind_param("ssddi", $nom, $code_postal, $latitude, $longitude, $is_active);
        }

        if ($stmt->execute()) {
            $new_id = $id ?: $conn->insert_id;
            http_response_code(200);
            echo json_encode([
                'success' => true,
                'message' => $id ? 'Ville modifiée avec succès' : 'Ville ajoutée avec succès',
                'id' => $new_id
            ]);
        } else {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Erreur: ' . $stmt->error]);
        }

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

