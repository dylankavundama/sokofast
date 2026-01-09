<?php
// send_admin_notification.php - Script pour envoyer une notification WhatsApp à l'admin
// Ce script peut être appelé automatiquement ou manuellement pour envoyer les notifications

require_once 'db_connection.php';
require_once 'whatsapp_notification.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

// Récupérer l'ID de la commande depuis les paramètres
$commandeId = $_GET['commande_id'] ?? $_POST['commande_id'] ?? null;

if (!$commandeId) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'ID de commande requis (paramètre: commande_id)'
    ]);
    exit;
}

// Envoyer la notification
$result = sendWhatsAppNewOrderToAdmin($conn, (int)$commandeId);

if ($result['success']) {
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Notification WhatsApp préparée avec succès',
        'whatsapp_url' => $result['whatsapp_url'],
        'admin_phone' => $result['admin_phone'],
        'note' => 'Ouvrez cette URL dans un navigateur pour envoyer le message WhatsApp'
    ]);
} else {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => $result['message']
    ]);
}

$conn->close();
?>

