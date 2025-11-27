<?php
// whatsapp_business_api.php - Intégration WhatsApp Business API

// 💡 Configuration WhatsApp Business API
// Obtenez ces informations depuis votre compte Meta Business : https://business.facebook.com/
define('WHATSAPP_ACCESS_TOKEN', 'VOTRE_ACCESS_TOKEN_ICI'); // Token d'accès permanent
define('WHATSAPP_PHONE_NUMBER_ID', 'VOTRE_PHONE_NUMBER_ID_ICI'); // ID du numéro WhatsApp Business
define('WHATSAPP_API_VERSION', 'v18.0'); // Version de l'API (v18.0 est la dernière stable)
define('WHATSAPP_BASE_URL', 'https://graph.facebook.com/' . WHATSAPP_API_VERSION);

/**
 * Envoie un message WhatsApp via WhatsApp Business API
 * 
 * @param string $to Numéro de téléphone du destinataire (format: 243812345678 avec code pays)
 * @param string $message Texte du message à envoyer
 * @return array ['success' => bool, 'message' => string, 'message_id' => string|null, 'error' => array|null]
 */
function sendWhatsAppMessageViaAPI($to, $message) {
    // Vérifier que les credentials sont configurés
    if (WHATSAPP_ACCESS_TOKEN === 'VOTRE_ACCESS_TOKEN_ICI' || 
        empty(WHATSAPP_ACCESS_TOKEN) ||
        WHATSAPP_PHONE_NUMBER_ID === 'VOTRE_PHONE_NUMBER_ID_ICI' ||
        empty(WHATSAPP_PHONE_NUMBER_ID)) {
        error_log("⚠️ WhatsApp Business API non configuré - Veuillez configurer les credentials dans whatsapp_business_api.php");
        return [
            'success' => false,
            'message' => 'WhatsApp Business API non configuré. Veuillez configurer les credentials dans whatsapp_business_api.php. Voir README_WHATSAPP_BUSINESS_API.md pour les instructions.',
            'message_id' => null,
            'error' => ['type' => 'configuration', 'message' => 'Credentials manquants - Configurez WHATSAPP_ACCESS_TOKEN et WHATSAPP_PHONE_NUMBER_ID']
        ];
    }
    
    // Formater le numéro de téléphone (doit être au format international sans le +)
    // Exemple: 243812345678 (RDC) ou 243977734735
    $phoneNumber = preg_replace('/[^0-9]/', '', $to);
    
    // Vérifier que le numéro est valide
    if (empty($phoneNumber) || strlen($phoneNumber) < 9) {
        return [
            'success' => false,
            'message' => 'Numéro de téléphone invalide',
            'message_id' => null,
            'error' => ['type' => 'validation', 'message' => 'Numéro invalide: ' . $to]
        ];
    }
    
    // Construire l'URL de l'API
    $url = WHATSAPP_BASE_URL . '/' . WHATSAPP_PHONE_NUMBER_ID . '/messages';
    
    // Préparer les données pour l'API
    $data = [
        'messaging_product' => 'whatsapp',
        'to' => $phoneNumber,
        'type' => 'text',
        'text' => [
            'body' => $message
        ]
    ];
    
    // Initialiser cURL
    $ch = curl_init($url);
    
    // Configurer les options cURL
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Authorization: Bearer ' . WHATSAPP_ACCESS_TOKEN,
        'Content-Type: application/json'
    ]);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true);
    curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 2);
    
    // Exécuter la requête
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlError = curl_error($ch);
    curl_close($ch);
    
    // Gérer les erreurs cURL
    if ($curlError) {
        error_log("WhatsApp API cURL Error: $curlError");
        return [
            'success' => false,
            'message' => 'Erreur de connexion: ' . $curlError,
            'message_id' => null,
            'error' => ['type' => 'curl', 'message' => $curlError]
        ];
    }
    
    // Décoder la réponse
    $responseData = json_decode($response, true);
    
    // Vérifier le code HTTP
    if ($httpCode >= 200 && $httpCode < 300) {
        // Succès
        $messageId = $responseData['messages'][0]['id'] ?? null;
        error_log("✅ WhatsApp message sent successfully via API - Message ID: $messageId, To: $phoneNumber, HTTP Code: $httpCode");
        
        return [
            'success' => true,
            'message' => 'Message WhatsApp envoyé avec succès via API',
            'message_id' => $messageId,
            'error' => null,
            'http_code' => $httpCode
        ];
    } else {
        // Erreur API
        $errorMessage = $responseData['error']['message'] ?? 'Erreur inconnue';
        $errorType = $responseData['error']['type'] ?? 'unknown';
        $errorCode = $responseData['error']['code'] ?? $httpCode;
        $errorSubcode = $responseData['error']['error_subcode'] ?? null;
        
        error_log("❌ WhatsApp API Error - HTTP Code: $httpCode, Error Code: $errorCode, Type: $errorType, Message: $errorMessage");
        
        // Messages d'erreur plus explicites selon le type d'erreur
        $userFriendlyMessage = $errorMessage;
        if ($errorCode == 190) {
            $userFriendlyMessage = "Token d'accès invalide ou expiré. Veuillez régénérer votre access token.";
        } elseif ($errorCode == 100) {
            $userFriendlyMessage = "Paramètres invalides. Vérifiez le format du numéro de téléphone.";
        } elseif ($errorCode == 131047) {
            $userFriendlyMessage = "Numéro de téléphone non autorisé. Le numéro doit être vérifié dans Meta Business ou vous devez utiliser un template.";
        } elseif ($errorCode == 131026) {
            $userFriendlyMessage = "Fenêtre de 24h expirée. Le destinataire doit vous avoir contacté dans les 24 dernières heures, ou utilisez un template pré-approuvé.";
        }
        
        return [
            'success' => false,
            'message' => "Erreur API WhatsApp: $userFriendlyMessage",
            'message_id' => null,
            'error' => [
                'type' => $errorType,
                'code' => $errorCode,
                'subcode' => $errorSubcode,
                'message' => $errorMessage,
                'http_code' => $httpCode,
                'full_response' => $responseData
            ]
        ];
    }
}

/**
 * Envoie un message WhatsApp avec template (pour les messages pré-approuvés)
 * 
 * @param string $to Numéro de téléphone du destinataire
 * @param string $templateName Nom du template approuvé
 * @param array $parameters Paramètres du template
 * @return array Résultat de l'envoi
 */
function sendWhatsAppTemplateMessage($to, $templateName, $parameters = []) {
    // Vérifier que les credentials sont configurés
    if (WHATSAPP_ACCESS_TOKEN === 'VOTRE_ACCESS_TOKEN_ICI' || 
        WHATSAPP_PHONE_NUMBER_ID === 'VOTRE_PHONE_NUMBER_ID_ICI') {
        return [
            'success' => false,
            'message' => 'WhatsApp Business API non configuré',
            'message_id' => null
        ];
    }
    
    $phoneNumber = preg_replace('/[^0-9]/', '', $to);
    
    $url = WHATSAPP_BASE_URL . '/' . WHATSAPP_PHONE_NUMBER_ID . '/messages';
    
    $data = [
        'messaging_product' => 'whatsapp',
        'to' => $phoneNumber,
        'type' => 'template',
        'template' => [
            'name' => $templateName,
            'language' => ['code' => 'fr']
        ]
    ];
    
    // Ajouter les paramètres si fournis
    if (!empty($parameters)) {
        $data['template']['components'] = [
            [
                'type' => 'body',
                'parameters' => array_map(function($param) {
                    return ['type' => 'text', 'text' => $param];
                }, $parameters)
            ]
        ];
    }
    
    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Authorization: Bearer ' . WHATSAPP_ACCESS_TOKEN,
        'Content-Type: application/json'
    ]);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    $responseData = json_decode($response, true);
    
    if ($httpCode >= 200 && $httpCode < 300) {
        return [
            'success' => true,
            'message' => 'Message template envoyé avec succès',
            'message_id' => $responseData['messages'][0]['id'] ?? null
        ];
    } else {
        return [
            'success' => false,
            'message' => $responseData['error']['message'] ?? 'Erreur inconnue',
            'message_id' => null,
            'error' => $responseData['error'] ?? null
        ];
    }
}

?>

