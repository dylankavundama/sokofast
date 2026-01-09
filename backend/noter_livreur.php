<?php
// noter_livreur.php - API pour noter un livreur

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'db_connection.php';
$conn->set_charset("utf8mb4");

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Méthode non autorisée']);
    exit();
}

try {
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!$data) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Données JSON invalides']);
        exit();
    }
    
    $transaction_id = $data['transaction_id'] ?? '';
    $livreur_id = isset($data['livreur_id']) ? (int)$data['livreur_id'] : 0;
    $client_name = $data['client_name'] ?? '';
    $note = isset($data['note']) ? (int)$data['note'] : 0;
    $commentaire = $data['commentaire'] ?? '';
    
    // Validation
    if (empty($transaction_id) || $livreur_id <= 0 || empty($client_name) || $note < 1 || $note > 5) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Données invalides. transaction_id, livreur_id, client_name et note (1-5) sont requis.'
        ]);
        exit();
    }
    
    // Vérifier si une note existe déjà pour cette commande et ce client
    $check_query = "SELECT id FROM notes_livreurs 
                    WHERE transaction_id = ? AND client_name = ?";
    $check_stmt = $conn->prepare($check_query);
    $check_stmt->bind_param("ss", $transaction_id, $client_name);
    $check_stmt->execute();
    $check_result = $check_stmt->get_result();
    
    if ($check_result->num_rows > 0) {
        // Mettre à jour la note existante
        $existing_note = $check_result->fetch_assoc();
        $update_query = "UPDATE notes_livreurs 
                        SET note = ?, commentaire = ?, created_at = NOW()
                        WHERE id = ?";
        $update_stmt = $conn->prepare($update_query);
        $update_stmt->bind_param("isi", $note, $commentaire, $existing_note['id']);
        
        if ($update_stmt->execute()) {
            // Récupérer l'ID de la commande pour le trigger
            $commande_query = "SELECT id FROM commandes WHERE transaction_id = ? LIMIT 1";
            $commande_stmt = $conn->prepare($commande_query);
            $commande_stmt->bind_param("s", $transaction_id);
            $commande_stmt->execute();
            $commande_result = $commande_stmt->get_result();
            $commande = $commande_result->fetch_assoc();
            $commande_id = $commande ? $commande['id'] : 0;
            
            // Mettre à jour manuellement la note moyenne (au cas où le trigger ne fonctionne pas)
            $avg_query = "UPDATE livreurs 
                          SET note_moyenne = (
                              SELECT AVG(note) 
                              FROM notes_livreurs 
                              WHERE livreur_id = ?
                          )
                          WHERE id = ?";
            $avg_stmt = $conn->prepare($avg_query);
            $avg_stmt->bind_param("ii", $livreur_id, $livreur_id);
            $avg_stmt->execute();
            $avg_stmt->close();
            
            echo json_encode([
                'success' => true,
                'message' => 'Note mise à jour avec succès',
                'note_id' => $existing_note['id']
            ]);
        } else {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => 'Erreur lors de la mise à jour de la note: ' . $update_stmt->error
            ]);
        }
        $update_stmt->close();
    } else {
        // Créer une nouvelle note
        // Récupérer l'ID de la commande
        $commande_query = "SELECT id FROM commandes WHERE transaction_id = ? LIMIT 1";
        $commande_stmt = $conn->prepare($commande_query);
        $commande_stmt->bind_param("s", $transaction_id);
        $commande_stmt->execute();
        $commande_result = $commande_stmt->get_result();
        $commande = $commande_result->fetch_assoc();
        $commande_id = $commande ? $commande['id'] : 0;
        
        $insert_query = "INSERT INTO notes_livreurs 
                        (commande_id, transaction_id, livreur_id, client_name, note, commentaire)
                        VALUES (?, ?, ?, ?, ?, ?)";
        $insert_stmt = $conn->prepare($insert_query);
        $insert_stmt->bind_param("isissi", $commande_id, $transaction_id, $livreur_id, $client_name, $note, $commentaire);
        
        if ($insert_stmt->execute()) {
            // Mettre à jour la note moyenne du livreur
            $avg_query = "UPDATE livreurs 
                          SET note_moyenne = (
                              SELECT AVG(note) 
                              FROM notes_livreurs 
                              WHERE livreur_id = ?
                          )
                          WHERE id = ?";
            $avg_stmt = $conn->prepare($avg_query);
            $avg_stmt->bind_param("ii", $livreur_id, $livreur_id);
            $avg_stmt->execute();
            $avg_stmt->close();
            
            echo json_encode([
                'success' => true,
                'message' => 'Note enregistrée avec succès',
                'note_id' => $insert_stmt->insert_id
            ]);
        } else {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => 'Erreur lors de l\'enregistrement de la note: ' . $insert_stmt->error
            ]);
        }
        $insert_stmt->close();
    }
    
    $check_stmt->close();
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erreur serveur: ' . $e->getMessage()
    ]);
}

$conn->close();
?>

