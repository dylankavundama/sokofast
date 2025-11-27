<?php
// add_livreur.php - Ajouter ou modifier un livreur

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
            echo json_encode(['success' => false, 'message' => 'ID du livreur requis pour la suppression']);
            exit();
        }
        
        // Vérifier s'il y a des commandes associées
        $check_commandes = $conn->prepare("SELECT COUNT(*) as total FROM commandes WHERE livreur_id = ?");
        $check_commandes->bind_param("i", $id);
        $check_commandes->execute();
        $result_commandes = $check_commandes->get_result();
        $nb_commandes = $result_commandes->fetch_assoc()['total'];
        $check_commandes->close();
        
        if ($nb_commandes > 0) {
            // Soft delete : désactiver le livreur au lieu de le supprimer
            $query = "UPDATE livreurs SET is_active = 0, is_available = 0, updated_at = NOW() WHERE id = ?";
            $stmt = $conn->prepare($query);
            $stmt->bind_param("i", $id);
            
            if ($stmt->execute()) {
                // Désactiver aussi les associations ville-livreur
                $update_assoc = $conn->prepare("UPDATE ville_livreur SET is_active = 0 WHERE livreur_id = ?");
                $update_assoc->bind_param("i", $id);
                $update_assoc->execute();
                $update_assoc->close();
                
                http_response_code(200);
                echo json_encode([
                    'success' => true,
                    'message' => 'Livreur désactivé avec succès (des commandes lui sont associées)',
                    'id' => $id
                ]);
            } else {
                http_response_code(500);
                echo json_encode(['success' => false, 'message' => 'Erreur lors de la désactivation: ' . $stmt->error]);
            }
            $stmt->close();
        } else {
            // Aucune commande associée : soft delete
            $query = "UPDATE livreurs SET is_active = 0, is_available = 0, updated_at = NOW() WHERE id = ?";
            $stmt = $conn->prepare($query);
            $stmt->bind_param("i", $id);
            
            if ($stmt->execute()) {
                // Désactiver aussi les associations ville-livreur
                $update_assoc = $conn->prepare("UPDATE ville_livreur SET is_active = 0 WHERE livreur_id = ?");
                $update_assoc->bind_param("i", $id);
                $update_assoc->execute();
                $update_assoc->close();
                
                http_response_code(200);
                echo json_encode([
                    'success' => true,
                    'message' => 'Livreur supprimé avec succès',
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
        $prenom = trim($data->prenom ?? '');
        $telephone = trim($data->telephone ?? '');
        $email = trim($data->email ?? '');
        $is_active = isset($data->is_active) ? (int)$data->is_active : 1;
        $is_available = isset($data->is_available) ? (int)$data->is_available : 1;
        $id = isset($data->id) ? (int)$data->id : null;

        if (empty($nom) || empty($prenom) || empty($telephone)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Nom, prénom et téléphone sont requis']);
            exit();
        }

        // Vérifier l'unicité du téléphone (sauf pour la modification de la même entrée)
        $check_query = "SELECT id FROM livreurs WHERE telephone = ?";
        if ($id) {
            $check_query .= " AND id != ?";
        }
        $check_stmt = $conn->prepare($check_query);
        if ($id) {
            $check_stmt->bind_param("si", $telephone, $id);
        } else {
            $check_stmt->bind_param("s", $telephone);
        }
        $check_stmt->execute();
        $check_result = $check_stmt->get_result();
        
        if ($check_result->num_rows > 0) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Ce numéro de téléphone est déjà utilisé']);
            $check_stmt->close();
            exit();
        }
        $check_stmt->close();

        if ($id) {
            // MODIFICATION
            $query = "UPDATE livreurs SET nom = ?, prenom = ?, telephone = ?, email = ?, is_active = ?, is_available = ?, updated_at = NOW() WHERE id = ?";
            $stmt = $conn->prepare($query);
            $stmt->bind_param("ssssiii", $nom, $prenom, $telephone, $email, $is_active, $is_available, $id);
        } else {
            // AJOUT
            $query = "INSERT INTO livreurs (nom, prenom, telephone, email, is_active, is_available) VALUES (?, ?, ?, ?, ?, ?)";
            $stmt = $conn->prepare($query);
            $stmt->bind_param("ssssii", $nom, $prenom, $telephone, $email, $is_active, $is_available);
        }

        if ($stmt->execute()) {
            $new_id = $id ?: $conn->insert_id;
            http_response_code(200);
            echo json_encode([
                'success' => true,
                'message' => $id ? 'Livreur modifié avec succès' : 'Livreur ajouté avec succès',
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

