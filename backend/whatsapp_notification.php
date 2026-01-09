<?php
// whatsapp_notification.php - Fonction utilitaire pour envoyer des notifications WhatsApp

// 💡 Configuration : Numéro de téléphone de l'admin (format: 243812345678)
define('ADMIN_WHATSAPP_PHONE', '243977734735'); // Modifiez ce numéro selon vos besoins

/**
 * Envoie une notification WhatsApp à l'admin pour une nouvelle commande
 * 
 * @param mysqli $conn Connexion à la base de données
 * @param int $commandeId ID de la commande créée
 * @return array ['success' => bool, 'message' => string, 'whatsapp_url' => string|null]
 */
function sendWhatsAppNewOrderToAdmin($conn, $commandeId) {
    try {
        // Récupérer toutes les informations de la commande
        $query = "SELECT c.*, 
                         l.nom as livreur_nom, l.prenom as livreur_prenom, l.telephone as livreur_telephone,
                         v.nom as ville_nom
                  FROM commandes c
                  LEFT JOIN livreurs l ON c.livreur_id = l.id
                  LEFT JOIN villes v ON c.ville_id = v.id
                  WHERE c.id = ?
                  ORDER BY c.order_date DESC
                  LIMIT 1";
        
        $stmt = $conn->prepare($query);
        if (!$stmt) {
            return ['success' => false, 'message' => 'Erreur de préparation SQL: ' . $conn->error];
        }
        
        $stmt->bind_param("i", $commandeId);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows === 0) {
            $stmt->close();
            return ['success' => false, 'message' => 'Commande non trouvée'];
        }
        
        $order = $result->fetch_assoc();
        $stmt->close();
        
        // Construire le message WhatsApp pour l'admin
        $message = "🛒 *NOUVELLE COMMANDE*\n\n";
        $message .= "━━━━━━━━━━━━━━━━━━━━\n\n";
        
        // Informations de base
        $message .= "📋 *Détails de la commande:*\n";
        $message .= "• ID Commande: #{$order['id']}\n";
        $message .= "• Transaction ID: {$order['transaction_id']}\n";
        $message .= "• Date: " . date('d/m/Y H:i', strtotime($order['order_date'])) . "\n\n";
        
        // Informations client
        $message .= "👤 *Client:*\n";
        $message .= "• Nom: {$order['name']}\n";
        $message .= "• Adresse: {$order['address']}\n";
        
        // Extraire le numéro de téléphone du client
        $clientPhone = extractPhoneFromPaymentMethod($order['payment_method']);
        if ($clientPhone) {
            $message .= "• Téléphone: $clientPhone\n";
        }
        $message .= "\n";
        
        // Produit
        $message .= "📦 *Produit:*\n";
        $message .= "• {$order['product_name']}\n";
        $message .= "• Quantité: {$order['quantity']}\n";
        // Calculer le prix unitaire (éviter division par zéro)
        $prix_unitaire = $order['quantity'] > 0 ? ($order['total_price'] / $order['quantity']) : $order['total_price'];
        $message .= "• Prix unitaire: " . number_format($prix_unitaire, 2) . " $\n";
        $message .= "• *Total: " . number_format($order['total_price'], 2) . " $*\n\n";
        
        // Méthode de paiement
        $message .= "💳 *Paiement:*\n";
        $message .= "• Méthode: {$order['payment_method']}\n";
        $message .= "• Statut: {$order['status']}\n\n";
        
        // Coordonnées GPS
        if (!empty($order['latitude']) && !empty($order['longitude'])) {
            $message .= "📍 *Localisation:*\n";
            $message .= "• Latitude: {$order['latitude']}\n";
            $message .= "• Longitude: {$order['longitude']}\n";
            $message .= "• Carte: https://maps.google.com/?q={$order['latitude']},{$order['longitude']}\n\n";
        }
        
        // Ville
        if (!empty($order['ville_nom'])) {
            $message .= "🏙️ *Ville:*\n";
            $message .= "• {$order['ville_nom']}\n\n";
        }
        
        // Livreur assigné
        if (!empty($order['livreur_nom']) && !empty($order['livreur_prenom'])) {
            $message .= "🚚 *Livreur assigné:*\n";
            $message .= "• {$order['livreur_prenom']} {$order['livreur_nom']}\n";
            if (!empty($order['livreur_telephone'])) {
                $message .= "• Téléphone: {$order['livreur_telephone']}\n";
            }
            $message .= "\n";
        } else {
            $message .= "⚠️ *Aucun livreur assigné*\n\n";
        }
        
        $message .= "━━━━━━━━━━━━━━━━━━━━\n";
        $message .= "Action requise: Traiter la commande\n";
        
        // 💡 NOUVEAU : Envoyer automatiquement via WhatsApp Business API
        require_once __DIR__ . '/whatsapp_business_api.php';
        $apiResult = sendWhatsAppMessageViaAPI(ADMIN_WHATSAPP_PHONE, $message);
        
        // Construire aussi l'URL WhatsApp (fallback si l'API échoue)
        $whatsappUrl = buildWhatsAppUrl(ADMIN_WHATSAPP_PHONE, $message);
        
        // Enregistrer la notification dans les logs
        error_log("WhatsApp notification admin - Commande ID: $commandeId, Transaction: {$order['transaction_id']}, API Success: " . ($apiResult['success'] ? 'Yes' : 'No'));
        
        if ($apiResult['success']) {
            return [
                'success' => true,
                'message' => 'Notification WhatsApp envoyée automatiquement à l\'admin',
                'whatsapp_url' => $whatsappUrl, // Garder l'URL comme fallback
                'admin_phone' => ADMIN_WHATSAPP_PHONE,
                'message_id' => $apiResult['message_id'],
                'api_sent' => true
            ];
        } else {
            // Si l'API échoue, retourner l'URL pour envoi manuel
            error_log("WhatsApp API Error: " . $apiResult['message']);
            return [
                'success' => true, // On considère que c'est un succès car on a l'URL
                'message' => 'Notification WhatsApp préparée (envoi API échoué: ' . $apiResult['message'] . ')',
                'whatsapp_url' => $whatsappUrl,
                'admin_phone' => ADMIN_WHATSAPP_PHONE,
                'message_id' => null,
                'api_sent' => false,
                'api_error' => $apiResult['error'] ?? null
            ];
        }
        
    } catch (Exception $e) {
        error_log("Erreur lors de la préparation de la notification WhatsApp admin: " . $e->getMessage());
        return ['success' => false, 'message' => 'Erreur: ' . $e->getMessage()];
    }
}

/**
 * Envoie une notification WhatsApp au client concernant une mise à jour de commande
 * 
 * @param mysqli $conn Connexion à la base de données
 * @param string $transactionId ID de transaction de la commande
 * @param string $newStatus Nouveau statut de la commande
 * @param string|null $customMessage Message personnalisé (optionnel)
 * @return array ['success' => bool, 'message' => string, 'whatsapp_url' => string|null]
 */
function sendWhatsAppOrderUpdate($conn, $transactionId, $newStatus, $customMessage = null) {
    try {
        // Récupérer les informations de la commande
        $query = "SELECT c.name, c.payment_method, c.product_name, c.quantity, c.total_price, c.address,
                         l.nom as livreur_nom, l.prenom as livreur_prenom, l.telephone as livreur_telephone
                  FROM commandes c
                  LEFT JOIN livreurs l ON c.livreur_id = l.id
                  WHERE c.transaction_id = ?
                  LIMIT 1";
        
        $stmt = $conn->prepare($query);
        if (!$stmt) {
            return ['success' => false, 'message' => 'Erreur de préparation SQL: ' . $conn->error];
        }
        
        $stmt->bind_param("s", $transactionId);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows === 0) {
            $stmt->close();
            return ['success' => false, 'message' => 'Commande non trouvée'];
        }
        
        $order = $result->fetch_assoc();
        $stmt->close();
        
        // Extraire le numéro de téléphone du client depuis payment_method
        $clientPhone = extractPhoneFromPaymentMethod($order['payment_method']);
        
        if (empty($clientPhone)) {
            return ['success' => false, 'message' => 'Numéro de téléphone non disponible pour cette commande'];
        }
        
        // Construire le message WhatsApp
        $statusMessages = [
            'en cours' => 'en cours de préparation',
            'EN COURS' => 'en cours de préparation',
            'PENDING' => 'en attente de confirmation',
            'CONFIRMED' => 'confirmée et en cours de préparation',
            'terminer' => 'terminée et prête pour la livraison',
            'TERMINER' => 'terminée et prête pour la livraison',
            'CONFIRMED' => 'confirmée',
            'annuler' => 'annulée',
            'ANNULER' => 'annulée',
            'FAILED' => 'échouée'
        ];
        
        $statusText = $statusMessages[strtolower($newStatus)] ?? strtolower($newStatus);
        
        // Message par défaut ou personnalisé
        if ($customMessage) {
            $message = $customMessage;
        } else {
            $message = "Bonjour {$order['name']},\n\n";
            $message .= "📦 Mise à jour de votre commande #{$transactionId}\n\n";
            $message .= "Votre commande est maintenant : *{$statusText}*\n\n";
            
            // Détails de la commande
            $message .= "📋 Détails :\n";
            $message .= "• Produit : {$order['product_name']}\n";
            $message .= "• Quantité : {$order['quantity']}\n";
            $message .= "• Montant total : " . number_format($order['total_price'], 2) . " $\n";
            $message .= "• Adresse : {$order['address']}\n\n";
            
            // Informations du livreur si disponible
            if (!empty($order['livreur_nom']) && !empty($order['livreur_prenom'])) {
                $message .= "🚚 Livreur assigné :\n";
                $message .= "• Nom : {$order['livreur_prenom']} {$order['livreur_nom']}\n";
                if (!empty($order['livreur_telephone'])) {
                    $message .= "• Téléphone : {$order['livreur_telephone']}\n";
                }
                $message .= "\n";
            }
            
            // Message selon le statut
            if (strtolower($newStatus) === 'terminer' || strtolower($newStatus) === 'terminé') {
                $message .= "✅ Votre commande a été livrée avec succès !\n";
                $message .= "Merci de votre confiance.\n\n";
            } elseif (strtolower($newStatus) === 'annuler' || strtolower($newStatus) === 'annulé') {
                $message .= "❌ Votre commande a été annulée.\n";
                $message .= "Pour plus d'informations, contactez-nous.\n\n";
            } else {
                $message .= "Nous vous tiendrons informé de l'avancement de votre commande.\n\n";
            }
            
            $message .= "Cordialement,\nL'équipe Soko";
        }
        
        // Construire l'URL WhatsApp
        $whatsappUrl = buildWhatsAppUrl($clientPhone, $message);
        
        // Enregistrer la notification dans les logs (optionnel)
        error_log("WhatsApp notification - Transaction: $transactionId, Phone: $clientPhone, Status: $newStatus");
        
        return [
            'success' => true,
            'message' => 'Notification WhatsApp préparée avec succès',
            'whatsapp_url' => $whatsappUrl,
            'client_phone' => $clientPhone
        ];
        
    } catch (Exception $e) {
        error_log("Erreur lors de la préparation de la notification WhatsApp: " . $e->getMessage());
        return ['success' => false, 'message' => 'Erreur: ' . $e->getMessage()];
    }
}

/**
 * Extrait le numéro de téléphone depuis payment_method
 * Formats supportés : "FlexPay:243812345678", "243812345678", "WhatsApp"
 * 
 * @param string $paymentMethod Méthode de paiement
 * @return string|null Numéro de téléphone ou null
 */
function extractPhoneFromPaymentMethod($paymentMethod) {
    if (empty($paymentMethod)) {
        return null;
    }
    
    // Format FlexPay:243812345678 ou WhatsApp:243812345678
    if (strpos($paymentMethod, ':') !== false) {
        $parts = explode(':', $paymentMethod);
        if (count($parts) >= 2) {
            $phone = trim($parts[1]);
            // Nettoyer le numéro (enlever les espaces, +, etc.)
            $phone = preg_replace('/[^0-9]/', '', $phone);
            // Vérifier que c'est un numéro valide (9 à 15 chiffres)
            if (preg_match('/^[0-9]{9,15}$/', $phone)) {
                return $phone;
            }
        }
    }
    
    // Format direct : 243812345678 (sans préfixe)
    $phone = trim($paymentMethod);
    // Nettoyer le numéro
    $phone = preg_replace('/[^0-9]/', '', $phone);
    if (preg_match('/^[0-9]{9,15}$/', $phone)) {
        return $phone;
    }
    
    // Si c'est juste "WhatsApp" ou autre texte, on ne peut pas extraire le numéro
    // Dans ce cas, on retourne null (le client devra être contacté manuellement)
    return null;
}

/**
 * Construit l'URL WhatsApp avec le message pré-rempli
 * 
 * @param string $phone Numéro de téléphone (format: 243812345678)
 * @param string $message Message à envoyer
 * @return string URL WhatsApp
 */
function buildWhatsAppUrl($phone, $message) {
    // Nettoyer le numéro (enlever les espaces, +, etc.)
    $phone = preg_replace('/[^0-9]/', '', $phone);
    
    // Encoder le message pour l'URL
    $encodedMessage = urlencode($message);
    
    // Construire l'URL WhatsApp
    return "https://api.whatsapp.com/send?phone={$phone}&text={$encodedMessage}";
}

/**
 * Envoie une notification WhatsApp pour une mise à jour de statut de commande
 * Version simplifiée pour utilisation directe
 * 
 * @param mysqli $conn Connexion à la base de données
 * @param int $commandeId ID de la commande
 * @param string $newStatus Nouveau statut
 * @return array Résultat de l'opération
 */
function notifyClientViaWhatsApp($conn, $commandeId, $newStatus) {
    // Récupérer le transaction_id depuis l'ID de commande
    $query = "SELECT transaction_id FROM commandes WHERE id = ? LIMIT 1";
    $stmt = $conn->prepare($query);
    if (!$stmt) {
        return ['success' => false, 'message' => 'Erreur SQL'];
    }
    
    $stmt->bind_param("i", $commandeId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        $stmt->close();
        return ['success' => false, 'message' => 'Commande non trouvée'];
    }
    
    $row = $result->fetch_assoc();
    $transactionId = $row['transaction_id'];
    $stmt->close();
    
    return sendWhatsAppOrderUpdate($conn, $transactionId, $newStatus);
}

?>

