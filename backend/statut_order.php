<?php
// ===============================================
// statut_order.php : API pour mettre à jour le statut de la commande
// ===============================================

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *'); 
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// --- 1. Configuration de la base de données ---
// Utilisation du fichier de configuration centralisé
require_once __DIR__ . '/db_connection.php';
// La connexion $conn est déjà créée dans db_connection.php avec le charset utf8mb4

// 💡 NOUVEAU : Inclure la fonction de notification WhatsApp
require_once 'whatsapp_notification.php';

// --- 2. Récupération des données POST ---
$data = json_decode(file_get_contents("php://input"), true);

$transactionId = $data['transaction_id'] ?? null;
// Le statut arrive en MAJUSCULES depuis Flutter (Ex: 'EN COURS', 'PENDING')
$newStatus = $data['status'] ?? null; 

if (empty($transactionId) || empty($newStatus)) {
    http_response_code(400); 
    echo json_encode(["success" => false, "message" => "Transaction ID ou statut manquant."]);
    $conn->close();
    exit;
}

// --- 3. Validation et Mise à Jour ---
// 💡 CORRECTION: Liste des statuts valides EN MAJUSCULES (pour correspondre à ce que Flutter envoie)
// Assurez-vous que cette liste correspond aux valeurs ENUM de votre base de données.
$validStatuses = ['EN COURS', 'TERMINER', 'ANNULER', 'PENDING', 'CONFIRMED', 'FAILED'];

if (!in_array($newStatus, $validStatuses)) {
    http_response_code(400); 
    echo json_encode(["success" => false, "message" => "Statut non valide ou non autorisé: " . htmlspecialchars($newStatus)]);
    $conn->close();
    exit;
}

// Requête préparée pour éviter l'injection SQL
// Note: Le champ 'updated_at' n'existe pas dans le schéma 'commandes.sql', 
// je l'ai retiré. Si vous l'ajoutez, remettez-le ici.
$stmt = $conn->prepare("UPDATE commandes SET status = ? WHERE transaction_id = ?");

$stmt->bind_param("ss", $newStatus, $transactionId);

if ($stmt->execute()) {
    if ($stmt->affected_rows > 0) {
        // 💡 NOUVEAU : Envoyer une notification WhatsApp au client
        $whatsappResult = sendWhatsAppOrderUpdate($conn, $transactionId, $newStatus);
        
        $response = [
            "success" => true,
            "message" => "Statut de la commande {$transactionId} mis à jour à '{$newStatus}'.",
            "whatsapp_notification" => [
                "sent" => $whatsappResult['success'],
                "url" => $whatsappResult['whatsapp_url'] ?? null,
                "message" => $whatsappResult['message'] ?? null
            ]
        ];
        
        echo json_encode($response);
    } else {
        echo json_encode(["success" => false, "message" => "Aucune ligne trouvée ou mise à jour pour la transaction {$transactionId}. Vérifiez l'ID."]);
    }
} else {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Erreur SQL lors de la mise à jour: " . $stmt->error]);
}

$stmt->close();
$conn->close();
?>