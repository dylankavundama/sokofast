<?php
/**
 * Fonction utilitaire pour les requêtes cURL vers les APIs internes
 * Gère les erreurs et retourne un tableau standardisé
 * 
 * @param string $url URL de l'API
 * @param array $data Données à envoyer (sera encodé en JSON)
 * @param string $method Méthode HTTP (POST, PUT, DELETE)
 * @return array ['success' => bool, 'data' => array|null, 'error' => string|null, 'http_code' => int]
 */
function callInternalAPI($url, $data = [], $method = 'POST') {
    $ch = curl_init($url);
    
    // Options de base
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, ($method === 'POST'));
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $method);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
        'Accept: application/json'
    ]);
    curl_setopt($ch, CURLOPT_TIMEOUT, 30); // Timeout de 30 secondes
    curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 10); // Timeout de connexion de 10 secondes
    
    // Exécuter la requête
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlError = curl_error($ch);
    $curlErrno = curl_errno($ch);
    curl_close($ch);
    
    // Vérifier les erreurs cURL
    if ($curlErrno !== 0 || $response === false) {
        error_log("Erreur cURL pour $url: [$curlErrno] $curlError");
        return [
            'success' => false,
            'data' => null,
            'error' => "Erreur de connexion: " . ($curlError ?: "Erreur inconnue (code: $curlErrno)"),
            'http_code' => 0
        ];
    }
    
    // Vérifier le code HTTP
    if ($httpCode < 200 || $httpCode >= 300) {
        error_log("Code HTTP d'erreur pour $url: $httpCode - Réponse: " . substr($response, 0, 500));
        $errorMessage = "Erreur serveur (code HTTP: $httpCode)";
        
        // Essayer de décoder le message d'erreur de la réponse
        $decoded = json_decode($response, true);
        if ($decoded && isset($decoded['message'])) {
            $errorMessage = $decoded['message'];
        } elseif (!empty($response)) {
            $errorMessage .= " - " . substr($response, 0, 200);
        }
        
        return [
            'success' => false,
            'data' => null,
            'error' => $errorMessage,
            'http_code' => $httpCode
        ];
    }
    
    // Décoder la réponse JSON
    $decoded = json_decode($response, true);
    if (json_last_error() !== JSON_ERROR_NONE) {
        error_log("Erreur de décodage JSON pour $url: " . json_last_error_msg() . " - Réponse: " . substr($response, 0, 500));
        return [
            'success' => false,
            'data' => null,
            'error' => "Réponse invalide du serveur: " . json_last_error_msg(),
            'http_code' => $httpCode
        ];
    }
    
    // Vérifier si la réponse indique un succès
    $success = isset($decoded['success']) ? $decoded['success'] : ($httpCode >= 200 && $httpCode < 300);
    
    return [
        'success' => $success,
        'data' => $decoded,
        'error' => $success ? null : ($decoded['message'] ?? 'Erreur inconnue'),
        'http_code' => $httpCode
    ];
}
?>

