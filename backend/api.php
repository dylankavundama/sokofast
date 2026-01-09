<?php
// Définit le type de contenu pour la réponse
header('Content-Type: application/json');

// --- 1. CONFIGURATION DE LA BASE DE DONNÉES ---
// Utilisation du fichier de configuration centralisé
require_once __DIR__ . '/db_connection.php';

define('LOG_FILE', __DIR__ . '/flexpay_callback.log'); // Chemin pour le fichier de logs

// Fonction utilitaire pour le logging
function log_message($message) {
    file_put_contents(LOG_FILE, date('[Y-m-d H:i:s] ') . $message . PHP_EOL, FILE_APPEND);
}

// --- 2. RÉCUPÉRATION DES DONNÉES ENVOYÉES PAR FLEXPAY ---
$data = file_get_contents('php://input');
$payload = json_decode($data, true);

log_message("Callback reçu. Payload: " . $data);

// Vérification de la présence des champs essentiels
if (!isset($payload['Reference']) || !isset($payload['Code'])) {
    log_message("Erreur: Champs Reference ou Code manquants dans le payload.");
    echo json_encode(['status' => 'error', 'message' => 'Invalid payload structure']);
    exit;
}

$reference_client = $payload['Reference']; // Votre 'referenceId' envoyé initialement
$code_flexpay = $payload['Code'];       // 0 pour Succès, Autre pour Échec
$order_number = $payload['orderNumber'] ?? 'N/A'; // Référence de FlexPay

// --- 3. CONNEXION À LA BASE DE DONNÉES ---
// La connexion $conn est déjà créée dans db_connection.php

// --- 4. TRAITEMENT DU STATUT FLEXPAY ---

// Déterminer le nouveau statut
if ($code_flexpay == '0') {
    $new_status = 'CONFIRMED';
    $log_message = "Succès de la transaction FlexPay. Référence client: $reference_client. Statut DB mis à JOUR.";
} else {
    $new_status = 'FAILED';
    $log_message = "Échec de la transaction FlexPay (Code: $code_flexpay). Référence client: $reference_client. Statut DB mis à ÉCHEC.";
}

// Préparer la requête SQL pour mettre à jour la commande
// La colonne 'transaction_id' de votre table de commandes doit correspondre à '$reference_client'
$sql = "UPDATE commandes 
        SET status = ?, flexpay_order_number = ?, updated_at = NOW() 
        WHERE transaction_id = ? AND status = 'PENDING'";

$stmt = $conn->prepare($sql);
if ($stmt === false) {
    log_message("Erreur de préparation SQL: " . $conn->error);
    $conn->close();
    echo json_encode(['status' => 'error', 'message' => 'SQL prepare error']);
    exit;
}

// Assurez-vous d'avoir une colonne 'flexpay_order_number' et 'updated_at' dans votre table 'commandes'
$stmt->bind_param("sss", $new_status, $order_number, $reference_client);
$execution_success = $stmt->execute();

// --- 5. RÉPONSE ET NETTOYAGE ---

if ($execution_success) {
    if ($stmt->affected_rows > 0) {
        log_message($log_message);
        $response_message = "Statut de la commande mis à jour à $new_status.";
    } else {
        // Cela peut arriver si la commande était déjà CONFIRMED ou n'existe pas
        log_message("Avertissement: Commande non trouvée ou déjà traitée pour référence: $reference_client. Statut reçu: $new_status.");
        $response_message = "Référence déjà traitée ou non trouvée.";
    }
    
    // Réponse de succès à FlexPay
    echo json_encode(['code' => 0, 'message' => 'Callback received and processed']);
} else {
    log_message("Erreur d'exécution DB pour référence $reference_client: " . $stmt->error);
    // Réponse d'erreur à FlexPay (peut indiquer qu'il faut réessayer)
    echo json_encode(['code' => 1, 'message' => 'Server failed to update database']);
}

$stmt->close();
$conn->close();

?>