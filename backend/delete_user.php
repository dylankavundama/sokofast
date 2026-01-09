<?php
// delete_user.php - Supprimer un utilisateur et toutes ses données associées

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

if (!$data) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Données JSON invalides']);
    exit();
}

try {
    $firebase_uid = trim($data->firebase_uid ?? '');
    $email = trim($data->email ?? '');

    if (empty($firebase_uid) && empty($email)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'firebase_uid ou email requis']);
        exit();
    }

    // Démarrer une transaction pour garantir la cohérence
    $conn->begin_transaction();

    try {
        // 1. Récupérer l'ID de l'utilisateur
        $user_query = "SELECT id FROM utilisateurs WHERE ";
        $user_params = [];
        $user_types = "";

        if (!empty($firebase_uid)) {
            $user_query .= "firebase_uid = ?";
            $user_params[] = $firebase_uid;
            $user_types .= "s";
        } else {
            $user_query .= "LOWER(email) = LOWER(?)";
            $user_params[] = $email;
            $user_types .= "s";
        }

        $user_stmt = $conn->prepare($user_query);
        if (!empty($user_types)) {
            $user_stmt->bind_param($user_types, ...$user_params);
        }
        $user_stmt->execute();
        $user_result = $user_stmt->get_result();
        
        if ($user_result->num_rows === 0) {
            $user_stmt->close();
            $conn->rollback();
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'Utilisateur non trouvé']);
            exit();
        }

        $user_data = $user_result->fetch_assoc();
        $user_id = $user_data['id'];
        $user_stmt->close();

        // 2. Supprimer les commentaires de l'utilisateur
        $delete_comments = $conn->prepare("DELETE FROM commentaires WHERE user_id = ?");
        $delete_comments->bind_param("i", $user_id);
        $delete_comments->execute();
        $delete_comments->close();

        // 3. Supprimer les notes de livreur données par l'utilisateur
        $delete_notes = $conn->prepare("DELETE FROM notes_livreur WHERE user_id = ?");
        $delete_notes->bind_param("i", $user_id);
        $delete_notes->execute();
        $delete_notes->close();

        // 4. Gérer les produits de l'utilisateur (si vendeur)
        // Option 1: Supprimer les produits (si vous voulez une suppression complète)
        // Option 2: Marquer les produits comme supprimés (soft delete)
        // Ici, on fait un soft delete pour préserver l'historique des commandes
        $update_products = $conn->prepare("UPDATE produits SET is_deleted = 1, deleted_at = NOW() WHERE user_id = ?");
        $update_products->bind_param("i", $user_id);
        $update_products->execute();
        $update_products->close();

        // 5. Gérer les commandes de l'utilisateur
        // On ne supprime pas les commandes car elles peuvent être importantes pour les statistiques
        // Mais on peut anonymiser les données personnelles
        $anonymize_orders = $conn->prepare("
            UPDATE commandes 
            SET name = 'Utilisateur supprimé', 
                address = 'Adresse supprimée',
                phone = NULL,
                email = NULL,
                user_id = NULL,
                updated_at = NOW()
            WHERE user_id = ?
        ");
        $anonymize_orders->bind_param("i", $user_id);
        $anonymize_orders->execute();
        $anonymize_orders->close();

        // 6. Si l'utilisateur est livreur, gérer les données livreur
        $check_livreur = $conn->prepare("SELECT id FROM livreurs WHERE firebase_uid = ? OR email = ?");
        $check_livreur->bind_param("ss", $firebase_uid, $email);
        $check_livreur->execute();
        $livreur_result = $check_livreur->get_result();
        
        if ($livreur_result->num_rows > 0) {
            $livreur_data = $livreur_result->fetch_assoc();
            $livreur_id = $livreur_data['id'];
            
            // Vérifier s'il y a des commandes en cours pour ce livreur
            $check_orders = $conn->prepare("SELECT COUNT(*) as total FROM commandes WHERE livreur_id = ? AND status IN ('EN COURS', 'EN PREPARATION')");
            $check_orders->bind_param("i", $livreur_id);
            $check_orders->execute();
            $orders_result = $check_orders->get_result();
            $nb_orders = $orders_result->fetch_assoc()['total'];
            $check_orders->close();
            
            if ($nb_orders > 0) {
                // Soft delete : désactiver le livreur
                $update_livreur = $conn->prepare("UPDATE livreurs SET is_active = 0, is_available = 0, updated_at = NOW() WHERE id = ?");
                $update_livreur->bind_param("i", $livreur_id);
                $update_livreur->execute();
                $update_livreur->close();
            } else {
                // Supprimer le livreur
                $delete_livreur_ville = $conn->prepare("DELETE FROM ville_livreur WHERE livreur_id = ?");
                $delete_livreur_ville->bind_param("i", $livreur_id);
                $delete_livreur_ville->execute();
                $delete_livreur_ville->close();
                
                $delete_livreur = $conn->prepare("DELETE FROM livreurs WHERE id = ?");
                $delete_livreur->bind_param("i", $livreur_id);
                $delete_livreur->execute();
                $delete_livreur->close();
            }
        }
        $check_livreur->close();

        // 7. Supprimer l'utilisateur de la table utilisateurs
        $delete_user = $conn->prepare("DELETE FROM utilisateurs WHERE id = ?");
        $delete_user->bind_param("i", $user_id);
        $delete_user->execute();
        $delete_user->close();

        // Valider la transaction
        $conn->commit();

        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'Utilisateur et toutes les données associées supprimés avec succès',
            'deleted_user_id' => $user_id
        ]);

    } catch (Exception $e) {
        // En cas d'erreur, annuler la transaction
        $conn->rollback();
        throw $e;
    }

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erreur lors de la suppression: ' . $e->getMessage()
    ]);
} finally {
    if (isset($conn)) {
        $conn->close();
    }
}
?>

