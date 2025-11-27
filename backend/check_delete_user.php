<?php
// check_delete_user.php - Vérifier si un utilisateur peut supprimer son compte

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

    // Récupérer l'ID de l'utilisateur
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
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'can_delete' => false,
            'message' => 'Utilisateur non trouvé'
        ]);
        exit();
    }

    $user_data = $user_result->fetch_assoc();
    $user_id = $user_data['id'];
    $user_stmt->close();

    $warnings = [];
    $can_delete = true;

    // Vérifier les commandes en cours
    $check_orders = $conn->prepare("
        SELECT COUNT(*) as total 
        FROM commandes 
        WHERE user_id = ? 
        AND status IN ('EN COURS', 'EN PREPARATION', 'PENDING')
    ");
    $check_orders->bind_param("i", $user_id);
    $check_orders->execute();
    $orders_result = $check_orders->get_result();
    $nb_orders = $orders_result->fetch_assoc()['total'];
    $check_orders->close();

    if ($nb_orders > 0) {
        $warnings[] = "Vous avez $nb_orders commande(s) en cours. Elles seront annulées.";
        // On autorise quand même la suppression, mais on avertit
    }

    // Vérifier si l'utilisateur est livreur avec des commandes en cours
    $check_livreur = $conn->prepare("
        SELECT l.id, COUNT(c.id) as nb_commandes
        FROM livreurs l
        LEFT JOIN commandes c ON c.livreur_id = l.id 
            AND c.status IN ('EN COURS', 'EN PREPARATION')
        WHERE l.firebase_uid = ? OR l.email = ?
        GROUP BY l.id
    ");
    $check_livreur->bind_param("ss", $firebase_uid, $email);
    $check_livreur->execute();
    $livreur_result = $check_livreur->get_result();
    
    if ($livreur_result->num_rows > 0) {
        $livreur_data = $livreur_result->fetch_assoc();
        $nb_livreur_orders = $livreur_data['nb_commandes'];
        
        if ($nb_livreur_orders > 0) {
            $warnings[] = "Vous êtes livreur avec $nb_livreur_orders commande(s) en cours. Votre compte livreur sera désactivé.";
        }
    }
    $check_livreur->close();

    // Vérifier les produits actifs (si vendeur)
    $check_products = $conn->prepare("
        SELECT COUNT(*) as total 
        FROM produits 
        WHERE user_id = ? 
        AND is_deleted = 0
    ");
    $check_products->bind_param("i", $user_id);
    $check_products->execute();
    $products_result = $check_products->get_result();
    $nb_products = $products_result->fetch_assoc()['total'];
    $check_products->close();

    if ($nb_products > 0) {
        $warnings[] = "Vous avez $nb_products produit(s) actif(s). Ils seront marqués comme supprimés.";
    }

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'can_delete' => $can_delete,
        'message' => $can_delete ? 'Vous pouvez supprimer votre compte' : 'Impossible de supprimer le compte',
        'warnings' => $warnings
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'can_delete' => false,
        'message' => 'Erreur lors de la vérification: ' . $e->getMessage(),
        'warnings' => []
    ]);
} finally {
    if (isset($conn)) {
        $conn->close();
    }
}
?>

