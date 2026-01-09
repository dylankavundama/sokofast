<?php
// attribuer_livreur.php - Fonction d'attribution automatique d'un livreur à une commande

require_once 'db_connection.php';

/**
 * Attribue automatiquement un livreur à une commande basé sur la ville
 * 
 * @param mysqli $conn Connexion à la base de données
 * @param int $commande_id ID de la commande
 * @param int $ville_id ID de la ville de livraison
 * @return int|null ID du livreur attribué ou null en cas d'échec
 */
function attribuerLivreurAutomatique($conn, $commande_id, $ville_id) {
    if (!$ville_id || $ville_id <= 0) {
        error_log("attribuerLivreurAutomatique: ville_id invalide ($ville_id)");
        return null;
    }
    
    error_log("attribuerLivreurAutomatique: Début pour commande_id=$commande_id, ville_id=$ville_id");
    
    try {
        // 💡 NOUVEAU : Par défaut, attribuer au livreur principal de la ville
        // 1. D'abord chercher un livreur principal disponible
        $query_principal = "SELECT l.id, l.nom, l.prenom, l.nombre_commandes_actuelles, vl.is_primary
                           FROM livreurs l
                           INNER JOIN ville_livreur vl ON l.id = vl.livreur_id
                           WHERE vl.ville_id = ? 
                             AND vl.is_primary = 1
                             AND vl.is_active = 1
                             AND l.is_active = 1 
                             AND l.is_available = 1
                           ORDER BY l.nombre_commandes_actuelles ASC, l.id ASC
                           LIMIT 1";
        
        $stmt_principal = $conn->prepare($query_principal);
        if ($stmt_principal === false) {
            error_log("Erreur préparation attribuerLivreur (principal): " . $conn->error);
            return null;
        }
        
        $stmt_principal->bind_param("i", $ville_id);
        $stmt_principal->execute();
        $result_principal = $stmt_principal->get_result();
        
        $livreur_id = null;
        
        if ($result_principal->num_rows > 0) {
            // Livreur principal trouvé
            $livreur = $result_principal->fetch_assoc();
            $livreur_id = (int)$livreur['id'];
            error_log("Livreur principal trouvé: ID=$livreur_id, Nom={$livreur['nom']} {$livreur['prenom']}, Commandes={$livreur['nombre_commandes_actuelles']}");
            $stmt_principal->close();
        } else {
            error_log("Aucun livreur principal disponible pour ville_id=$ville_id, recherche livreur secondaire...");
            // Aucun livreur principal disponible, chercher un livreur secondaire
            $stmt_principal->close();
            
            $query_secondaire = "SELECT l.id, l.nom, l.prenom, l.nombre_commandes_actuelles, vl.is_primary
                                FROM livreurs l
                                INNER JOIN ville_livreur vl ON l.id = vl.livreur_id
                                WHERE vl.ville_id = ? 
                                  AND vl.is_active = 1
                                  AND l.is_active = 1 
                                  AND l.is_available = 1
                                ORDER BY l.nombre_commandes_actuelles ASC, l.id ASC
                                LIMIT 1";
            
            $stmt_secondaire = $conn->prepare($query_secondaire);
            if ($stmt_secondaire === false) {
                error_log("Erreur préparation attribuerLivreur (secondaire): " . $conn->error);
                return null;
            }
            
            $stmt_secondaire->bind_param("i", $ville_id);
            $stmt_secondaire->execute();
            $result_secondaire = $stmt_secondaire->get_result();
            
            if ($result_secondaire->num_rows === 0) {
                // Aucun livreur disponible pour cette ville
                error_log("Aucun livreur disponible pour la ville ID: $ville_id");
                $stmt_secondaire->close();
                return null;
            }
            
            $livreur = $result_secondaire->fetch_assoc();
            $livreur_id = (int)$livreur['id'];
            error_log("Livreur secondaire trouvé: ID=$livreur_id, Nom={$livreur['nom']} {$livreur['prenom']}, Commandes={$livreur['nombre_commandes_actuelles']}");
            $stmt_secondaire->close();
        }
        
        // 2. Mettre à jour la commande avec le livreur attribué
        if ($livreur_id === null) {
            return null;
        }
        
        $update_query = "UPDATE commandes 
                        SET livreur_id = ?, attribution_date = NOW() 
                        WHERE id = ?";
        
        $update_stmt = $conn->prepare($update_query);
        if ($update_stmt === false) {
            error_log("Erreur préparation update commande: " . $conn->error);
            return null;
        }
        
        $update_stmt->bind_param("ii", $livreur_id, $commande_id);
        $success = $update_stmt->execute();
        
        if (!$success) {
            error_log("Erreur mise à jour commande: " . $update_stmt->error);
            $update_stmt->close();
            return null;
        }
        
        $update_stmt->close();
        
        // 3. Incrémenter le nombre de commandes actuelles du livreur
        $increment_query = "UPDATE livreurs 
                           SET nombre_commandes_actuelles = nombre_commandes_actuelles + 1 
                           WHERE id = ?";
        
        $increment_stmt = $conn->prepare($increment_query);
        if ($increment_stmt !== false) {
            $increment_stmt->bind_param("i", $livreur_id);
            $increment_stmt->execute();
            $increment_stmt->close();
        }
        
        return $livreur_id;
        
    } catch (Exception $e) {
        error_log("Exception dans attribuerLivreurAutomatique: " . $e->getMessage());
        return null;
    }
}

/**
 * Trouve la ville correspondant à une adresse (par géocodage inverse ou recherche textuelle)
 * 
 * @param mysqli $conn Connexion à la base de données
 * @param string $address Adresse de livraison
 * @param float|null $latitude Latitude GPS (optionnel)
 * @param float|null $longitude Longitude GPS (optionnel)
 * @return int|null ID de la ville trouvée ou null
 */
function trouverVilleParAdresse($conn, $address, $latitude = null, $longitude = null) {
    // Si on a des coordonnées GPS, on peut faire une recherche par proximité
    if ($latitude && $longitude) {
        // Recherche par proximité (rayon de ~50km)
        $query = "SELECT id, nom, 
                         (6371 * acos(cos(radians(?)) * cos(radians(latitude)) * 
                          cos(radians(longitude) - radians(?)) + 
                          sin(radians(?)) * sin(radians(latitude)))) AS distance
                  FROM villes 
                  WHERE is_active = 1 AND latitude IS NOT NULL AND longitude IS NOT NULL
                  HAVING distance < 50
                  ORDER BY distance ASC
                  LIMIT 1";
        
        $stmt = $conn->prepare($query);
        if ($stmt !== false) {
            $stmt->bind_param("ddd", $latitude, $longitude, $latitude);
            $stmt->execute();
            $result = $stmt->get_result();
            
            if ($result->num_rows > 0) {
                $row = $result->fetch_assoc();
                $stmt->close();
                return (int)$row['id'];
            }
            $stmt->close();
        }
    }
    
    // Fallback: recherche textuelle dans l'adresse
    $address_lower = strtolower($address);
    
    $query = "SELECT id, nom FROM villes WHERE is_active = 1";
    $result = $conn->query($query);
    
    if ($result) {
        while ($row = $result->fetch_assoc()) {
            $ville_nom_lower = strtolower($row['nom']);
            // Vérifier si le nom de la ville est présent dans l'adresse
            if (strpos($address_lower, $ville_nom_lower) !== false) {
                return (int)$row['id'];
            }
        }
    }
    
    return null;
}

/**
 * API endpoint pour attribution manuelle d'un livreur
 * 💡 CORRECTION : Ne s'exécute que si le fichier est appelé directement (pas via require_once)
 */
// Vérifier si le fichier est appelé directement (endpoint API) ou inclus (bibliothèque)
$is_direct_request = basename($_SERVER['PHP_SELF']) === 'attribuer_livreur.php';

if ($is_direct_request && $_SERVER['REQUEST_METHOD'] === 'POST') {
    header("Content-Type: application/json; charset=utf-8");
    header("Access-Control-Allow-Origin: *");
    header("Access-Control-Allow-Methods: POST, OPTIONS");
    header("Access-Control-Allow-Headers: Content-Type");
    
    if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        http_response_code(200);
        exit();
    }
    
    $input_data = file_get_contents("php://input");
    $data = json_decode($input_data);
    
    if (!isset($data->commande_id) || !isset($data->livreur_id)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'commande_id et livreur_id sont requis'
        ]);
        exit();
    }
    
    $commande_id = (int)$data->commande_id;
    $livreur_id = (int)$data->livreur_id;
    
    try {
        // Vérifier que la commande existe
        $check_query = "SELECT livreur_id FROM commandes WHERE id = ?";
        $check_stmt = $conn->prepare($check_query);
        $check_stmt->bind_param("i", $commande_id);
        $check_stmt->execute();
        $check_result = $check_stmt->get_result();
        
        if ($check_result->num_rows === 0) {
            http_response_code(404);
            echo json_encode([
                'success' => false,
                'message' => 'Commande non trouvée'
            ]);
            $check_stmt->close();
            exit();
        }
        
        $commande = $check_result->fetch_assoc();
        $ancien_livreur_id = $commande['livreur_id'];
        $check_stmt->close();
        
        // Si un livreur était déjà attribué, décrémenter son compteur
        if ($ancien_livreur_id) {
            $decrement_query = "UPDATE livreurs 
                               SET nombre_commandes_actuelles = GREATEST(nombre_commandes_actuelles - 1, 0) 
                               WHERE id = ?";
            $decrement_stmt = $conn->prepare($decrement_query);
            $decrement_stmt->bind_param("i", $ancien_livreur_id);
            $decrement_stmt->execute();
            $decrement_stmt->close();
        }
        
        // Attribuer le nouveau livreur
        $update_query = "UPDATE commandes 
                        SET livreur_id = ?, attribution_date = NOW() 
                        WHERE id = ?";
        
        $update_stmt = $conn->prepare($update_query);
        $update_stmt->bind_param("ii", $livreur_id, $commande_id);
        $update_stmt->execute();
        
        if ($update_stmt->affected_rows > 0) {
            // Incrémenter le compteur du nouveau livreur
            $increment_query = "UPDATE livreurs 
                               SET nombre_commandes_actuelles = nombre_commandes_actuelles + 1 
                               WHERE id = ?";
            $increment_stmt = $conn->prepare($increment_query);
            $increment_stmt->bind_param("i", $livreur_id);
            $increment_stmt->execute();
            $increment_stmt->close();
            
            http_response_code(200);
            echo json_encode([
                'success' => true,
                'message' => 'Livreur attribué avec succès',
                'livreur_id' => $livreur_id
            ]);
        } else {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => 'Erreur lors de l\'attribution'
            ]);
        }
        
        $update_stmt->close();
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => $e->getMessage()
        ]);
    } finally {
        if (isset($conn)) {
            $conn->close();
        }
    }
}
// 💡 FIN : Le code de l'endpoint API ne s'exécute que si le fichier est appelé directement
?>

