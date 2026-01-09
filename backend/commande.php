<?php
// commande.php

// --- Configuration des erreurs AVANT tout ---
error_reporting(E_ALL);
ini_set('display_errors', 0); // 0 pour la production
ini_set('log_errors', 1);
// Assurez-vous que ce chemin est correct pour votre serveur
ini_set('error_log', '/home/babutikc/public_html/php-error.log'); 

// 💡 NOUVEAU : Gestionnaire d'erreur global pour capturer les erreurs fatales
register_shutdown_function(function() {
    $error = error_get_last();
    if ($error !== NULL && in_array($error['type'], [E_ERROR, E_PARSE, E_CORE_ERROR, E_COMPILE_ERROR])) {
        // Erreur fatale détectée
        http_response_code(500);
        header("Content-Type: application/json");
        header("Access-Control-Allow-Origin: *");
        echo json_encode([
            "message" => "Erreur fatale du serveur",
            "debug" => [
                "error_type" => $error['type'],
                "error_message" => $error['message'],
                "error_file" => $error['file'],
                "error_line" => $error['line']
            ]
        ]);
    }
});

// 💡 NOUVEAU : Gestionnaire d'exceptions non capturées
set_exception_handler(function($exception) {
    http_response_code(500);
    header("Content-Type: application/json");
    header("Access-Control-Allow-Origin: *");
    error_log("Exception non capturée: " . $exception->getMessage() . " dans " . $exception->getFile() . " ligne " . $exception->getLine());
    echo json_encode([
        "message" => "Erreur serveur: " . $exception->getMessage(),
        "debug" => [
            "exception_type" => get_class($exception),
            "file" => $exception->getFile(),
            "line" => $exception->getLine(),
            "trace" => $exception->getTraceAsString()
        ]
    ]);
    exit();
});

// --- Entêtes CORS ---
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Access-Control-Max-Age: 86400");

// --- Configuration de la base de données ---
// Utilisation du fichier de configuration centralisé
try {
    require_once __DIR__ . '/db_connection.php';
    // La connexion $conn est déjà créée dans db_connection.php avec le charset utf8mb4
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        "message" => "Erreur de connexion à la base de données",
        "debug" => ["error" => $e->getMessage()]
    ]);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// --- Vérification de la méthode ---
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(["message" => "Erreur: Méthode non autorisée. Seules les requêtes POST sont acceptées."]);
    exit();
}

// --- Récupération et décodage JSON ---
$input_data = file_get_contents("php://input");

// 💡 LOG : Enregistrer les données reçues pour debug
error_log("Commande reçue - Données brutes: " . substr($input_data, 0, 500));

$data = json_decode($input_data);

if (json_last_error() !== JSON_ERROR_NONE || !is_object($data)) {
    http_response_code(400);
    $error_msg = "Erreur: Données JSON invalides. Détail: " . json_last_error_msg();
    error_log($error_msg . " - Données reçues: " . substr($input_data, 0, 200));
    echo json_encode(["message" => $error_msg, "debug" => ["json_error" => json_last_error_msg(), "input_preview" => substr($input_data, 0, 200)]]);
    exit();
}

// --- Champs requis (les coordonnées ne sont pas obligatoires ici car elles peuvent être nulles) ---
$required_fields = ['name', 'address', 'transaction_id', 'product_name', 'quantity', 'payment_method', 'total_price'];

foreach ($required_fields as $field) {
    if (!isset($data->$field) || (empty($data->$field) && $data->$field !== 0 && $data->$field !== '0')) {
        http_response_code(400);
        $error_msg = "Erreur: Le champ '" . $field . "' est manquant ou vide.";
        error_log($error_msg . " - Champs reçus: " . json_encode(array_keys((array)$data)));
        echo json_encode([
            "message" => $error_msg,
            "debug" => [
                "missing_field" => $field,
                "received_fields" => array_keys((array)$data)
            ]
        ]);
        exit();
    }
}

// --- Validation des types numériques ---
if (!is_numeric($data->quantity) || !is_numeric($data->total_price)) {
    http_response_code(400);
    echo json_encode(["message" => "Erreur: 'quantity' et 'total_price' doivent être numériques."]);
    exit();
}

// --- Extraction et assainissement ---
$name             = (string) $data->name;
$address          = (string) $data->address;
$transaction_id   = (string) $data->transaction_id;
$product_name     = (string) $data->product_name;
$quantity         = (int)    $data->quantity;
$payment_method   = (string) $data->payment_method;
$total_price      = (float)  $data->total_price;
$status           = isset($data->status) ? (string) $data->status : 'en cours'; // Statut envoyé par Flutter ou 'en cours' par défaut

// 💡 CORRECTION : Normaliser le statut pour correspondre au format de la base de données
// La base de données utilise un ENUM avec des valeurs en MINUSCULES : 'en cours', 'terminer', 'annuler'
// Convertir en minuscules et valider contre les valeurs autorisées
$status_trimmed = trim($status);
$status_normalized = strtolower($status_trimmed);
$valid_statuses = ['en cours', 'terminer', 'annuler'];
// Si le statut n'est pas valide, utiliser 'en cours' par défaut
if (!in_array($status_normalized, $valid_statuses)) {
    // Mapper les variantes communes (en majuscules ou avec accents)
    $status_upper = strtoupper($status_trimmed);
    $status_mapping = [
        'PENDING' => 'en cours',
        'EN COURS' => 'en cours',
        'EN_COURS' => 'en cours',
        'TERMINÉ' => 'terminer',
        'TERMINEE' => 'terminer',
        'TERMINÉE' => 'terminer',
        'TERMINER' => 'terminer',
        'ANNULE' => 'annuler',
        'ANNULÉ' => 'annuler',
        'ANNULÉE' => 'annuler',
        'ANNULER' => 'annuler'
    ];
    $status_normalized = isset($status_mapping[$status_upper]) 
        ? $status_mapping[$status_upper] 
        : 'en cours';
}
$status = $status_normalized;
$original_status = isset($data->status) ? $data->status : 'N/A';
error_log("Statut normalisé: '$status' (original: '$original_status')");

// 💡 NOUVEAU : Récupération et conversion des coordonnées
// Si la valeur est null ou non numérique, on utilise 0.0 pour la liaison (bind_param)
$latitude         = isset($data->latitude) && is_numeric($data->latitude) ? (float) $data->latitude : 0.0;
$longitude        = isset($data->longitude) && is_numeric($data->longitude) ? (float) $data->longitude : 0.0;

// 💡 NOUVEAU : Récupération de la ville (si fournie directement)
$ville_id = null;
if (isset($data->ville_id)) {
    // Accepter null, 0, ou un entier positif
    if ($data->ville_id === null) {
        $ville_id = null;
    } elseif (is_numeric($data->ville_id) && (int)$data->ville_id > 0) {
        $ville_id = (int)$data->ville_id;
    }
}

// 💡 LOG : Enregistrer le ville_id reçu
error_log("Commande reçue - ville_id depuis JSON: " . ($ville_id ?? 'null'));

// 💡 NOUVEAU : Si ville_id n'est pas fourni, essayer de le trouver par l'adresse
// 💡 CORRECTION : Ajouter try-catch pour gérer les erreurs
if (!$ville_id) {
    try {
        require_once 'attribuer_livreur.php';
        $ville_id = trouverVilleParAdresse($conn, $address, $latitude, $longitude);
        error_log("Commande - ville_id trouvé par adresse: " . ($ville_id ?? 'null'));
    } catch (Exception $e) {
        error_log("Erreur trouverVilleParAdresse: " . $e->getMessage());
        // Continuer avec ville_id = null (ne pas bloquer la commande)
        $ville_id = null;
    } catch (Error $e) {
        error_log("Erreur fatale trouverVilleParAdresse: " . $e->getMessage());
        $ville_id = null;
    }
}

// --- Requête préparée (11 champs avec ville_id) ---
// 💡 CORRECTION : Utiliser une valeur conditionnelle pour ville_id
// Si ville_id est null ou 0, on utilise NULL dans la requête
if ($ville_id && $ville_id > 0) {
    $query = "INSERT INTO commandes (name, address, transaction_id, product_name, quantity, payment_method, total_price, status, latitude, longitude, ville_id)
              VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"; // 11 placeholders avec ville_id
    $bind_types = "ssssisdsddi"; // avec ville_id
} else {
    $query = "INSERT INTO commandes (name, address, transaction_id, product_name, quantity, payment_method, total_price, status, latitude, longitude, ville_id)
              VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL)"; // NULL directement dans la requête
    $bind_types = "ssssisdsdd"; // sans ville_id (10 paramètres)
}

$stmt = $conn->prepare($query);

if ($stmt === false) {
    error_log("Erreur préparation SQL: " . $conn->error);
    http_response_code(500);
    echo json_encode(["message" => "Erreur interne du serveur lors de la préparation."]);
    $conn->close();
    exit();
}

// 💡 LOG : Enregistrer les valeurs avant bind
error_log("Valeurs avant bind_param - name: $name, address: $address, transaction_id: $transaction_id, product_name: $product_name, quantity: $quantity, payment_method: $payment_method, total_price: $total_price, status: $status, latitude: $latitude, longitude: $longitude, ville_id: " . ($ville_id ?? 'null'));

// 💡 CORRECTION : bind_param selon si ville_id est présent ou non
if ($ville_id && $ville_id > 0) {
    $bind_success = $stmt->bind_param($bind_types, 
        $name, 
        $address, 
        $transaction_id, 
        $product_name, 
        $quantity, 
        $payment_method, 
        $total_price, 
        $status, 
        $latitude, 
        $longitude,
        $ville_id // 💡 ville_id présent
    );
} else {
    $bind_success = $stmt->bind_param($bind_types, 
        $name, 
        $address, 
        $transaction_id, 
        $product_name, 
        $quantity, 
        $payment_method, 
        $total_price, 
        $status, 
        $latitude, 
        $longitude
        // 💡 ville_id omis (NULL dans la requête)
    );
}

if ($bind_success === false) {
    error_log("Erreur bind_param: " . $stmt->error);
    http_response_code(500);
    echo json_encode(["message" => "Erreur serveur lors du liage des paramètres."]);
    $stmt->close();
    $conn->close();
    exit();
}

// --- Exécution ---
try {
    $execute_success = $stmt->execute();
} catch (Exception $e) {
    error_log("Exception lors de l'exécution SQL: " . $e->getMessage());
    error_log("Stack trace: " . $e->getTraceAsString());
    http_response_code(500);
    echo json_encode([
        "message" => "Erreur lors de l'enregistrement de la commande.",
        "debug" => [
            "exception" => $e->getMessage(),
            "sql_error" => $stmt->error ?? 'N/A',
            "sql_errno" => $stmt->errno ?? 'N/A',
            "file" => $e->getFile(),
            "line" => $e->getLine()
        ]
    ]);
    $stmt->close();
    $conn->close();
    exit();
} catch (Error $e) {
    error_log("Erreur fatale lors de l'exécution SQL: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        "message" => "Erreur fatale lors de l'enregistrement de la commande.",
        "debug" => [
            "error" => $e->getMessage(),
            "file" => $e->getFile(),
            "line" => $e->getLine()
        ]
    ]);
    $stmt->close();
    $conn->close();
    exit();
}

if ($execute_success) {
    $commande_id = $conn->insert_id;
    
    // 💡 LOG : Enregistrer la commande créée
    error_log("Commande créée - ID: $commande_id, ville_id: " . ($ville_id ?? 'null'));
    
    // 💡 NOUVEAU : Attribution automatique d'un livreur si une ville a été trouvée
    // 💡 CORRECTION : Ajouter try-catch pour gérer les erreurs
    $livreur_id = null;
    if ($ville_id && $ville_id > 0) {
        try {
            require_once 'attribuer_livreur.php';
            error_log("Tentative d'attribution livreur pour ville_id: $ville_id");
            $livreur_id = attribuerLivreurAutomatique($conn, $commande_id, $ville_id);
            error_log("Livreur attribué - ID: " . ($livreur_id ?? 'null'));
        } catch (Exception $e) {
            error_log("Erreur attribution livreur: " . $e->getMessage());
            // Continuer sans livreur (ne pas bloquer la commande)
            $livreur_id = null;
        } catch (Error $e) {
            error_log("Erreur fatale attribution livreur: " . $e->getMessage());
            $livreur_id = null;
        }
    } else {
        error_log("Aucune attribution - ville_id invalide ou null: " . ($ville_id ?? 'null'));
    }
    
    // 💡 NOUVEAU : Envoyer une notification WhatsApp à l'admin via WhatsApp Business API
    require_once 'whatsapp_notification.php';
    $adminNotification = sendWhatsAppNewOrderToAdmin($conn, $commande_id);
    if ($adminNotification['success']) {
        if (isset($adminNotification['api_sent']) && $adminNotification['api_sent']) {
            error_log("✅ Notification WhatsApp admin envoyée automatiquement via API - Message ID: " . ($adminNotification['message_id'] ?? 'N/A'));
        } else {
            error_log("⚠️ Notification WhatsApp admin préparée (envoi API échoué) - URL: " . ($adminNotification['whatsapp_url'] ?? 'N/A'));
        }
    } else {
        error_log("❌ Échec notification WhatsApp admin: " . ($adminNotification['message'] ?? 'Erreur inconnue'));
    }
    
    http_response_code(201);
    $response = [
        "message" => "Commande enregistrée avec succès", 
        "id" => $commande_id,
        "ville_id" => $ville_id
    ];
    
    if ($livreur_id) {
        $response["livreur_id"] = $livreur_id;
        $response["message"] .= " - Livreur principal attribué automatiquement";
    } else if ($ville_id && $ville_id > 0) {
        $response["message"] .= " - Aucun livreur disponible pour cette ville";
    } else {
        $response["message"] .= " - Ville non identifiée, attribution manuelle requise";
    }
    
    // Ajouter l'information sur la notification admin (pour debug/logging)
    if (isset($adminNotification['whatsapp_url'])) {
        $response["admin_notification"] = [
            "sent" => $adminNotification['success'],
            "api_sent" => $adminNotification['api_sent'] ?? false,
            "message_id" => $adminNotification['message_id'] ?? null,
            "url" => $adminNotification['whatsapp_url'],
            "message" => $adminNotification['message'] ?? null
        ];
        if (isset($adminNotification['api_error'])) {
            $response["admin_notification"]["api_error"] = $adminNotification['api_error'];
        }
    }
    
    echo json_encode($response);
} else {
    // 💡 CORRECTION : Améliorer le logging des erreurs SQL avec plus de détails
    $error_details = [
        "sql_error" => $stmt->error,
        "sql_errno" => $stmt->errno,
        "sql_state" => $stmt->sqlstate ?? 'N/A',
        "query_preview" => substr($query, 0, 200)
    ];
    error_log("Erreur exécution SQL: " . json_encode($error_details));
    http_response_code(500);
    echo json_encode([
        "message" => "Erreur lors de l'enregistrement de la commande.",
        "debug" => $error_details
    ]);
}

// --- Fermeture ---
$stmt->close();
$conn->close();