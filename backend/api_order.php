<?php
// ===============================================
// api_order.php : API JSON sécurisée avec requêtes préparées
// ===============================================

header('Content-Type: application/json');
// Meilleurs headers de cache pour une API
header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
header('Pragma: no-cache');
header('Expires: 0');
header('Access-Control-Allow-Origin: *'); 

// Définition des fonctions d'erreur pour uniformiser la réponse
function send_error($message, $code = 500) {
    http_response_code($code);
    echo json_encode(["error" => $message]);
    exit;
}

// --- 1. Configuration de la base de données ---
// Utilisation du fichier de configuration centralisé
require_once __DIR__ . '/db_connection.php';
// La connexion $conn est déjà créée dans db_connection.php avec le charset utf8mb4

// --- 2. Récupération et préparation des paramètres de FILTRAGE ---
// L'opérateur de coalescence null `??` est parfait pour cela.
$startDate = $_GET['start_date'] ?? null;
$endDate = $_GET['end_date'] ?? null;
$statusFilter = $_GET['status'] ?? null; // Récupération du statut
$livreurEmail = $_GET['livreur_email'] ?? null; // 💡 NOUVEAU : Email du livreur

// --- 3. Construction dynamique de la requête SQL SÉCURISÉE ---
$whereConditions = ["1"]; // Condition de base
$paramTypes = "";
$paramValues = [];

// 💡 NOUVEAU : Filtrer par livreur si l'email est fourni
if ($livreurEmail) {
    // Joindre avec la table livreurs pour filtrer par email
    $whereConditions[] = "EXISTS (
        SELECT 1 FROM livreurs l 
        WHERE l.id = c.livreur_id 
        AND LOWER(l.email) = LOWER(?)
        AND l.is_active = 1
    )";
    $paramTypes .= "s";
    $paramValues[] = $livreurEmail;
}

if ($startDate) {
    // Note: Utiliser '?' comme placeholder pour les requêtes préparées
    $whereConditions[] = "DATE(c.order_date) >= ?";
    $paramTypes .= "s"; // 's' pour string
    $paramValues[] = $startDate;
}

if ($endDate) {
    $whereConditions[] = "DATE(c.order_date) <= ?";
    $paramTypes .= "s";
    $paramValues[] = $endDate;
}

if ($statusFilter) {
    // Le statut est envoyé en MAJUSCULES (ex: EN COURS).
    $whereConditions[] = "c.status = ?";
    $paramTypes .= "s";
    $paramValues[] = strtoupper($statusFilter); // Conversion en majuscule au cas où
}

$whereClause = implode(" AND ", $whereConditions);

$query = "
    SELECT 
        c.transaction_id, 
        MAX(c.name) AS name, 
        MAX(c.address) AS address, 
        MAX(c.status) AS status, 
        MAX(c.payment_method) AS payment_method, 
        MAX(c.order_date) AS order_date, 
        MAX(c.latitude) AS latitude, 
        MAX(c.longitude) AS longitude, 
        SUM(c.total_price) AS total_price, 
        GROUP_CONCAT(CONCAT(c.product_name, ' (', c.quantity, ')') SEPARATOR ' | ') AS products_summary 
    FROM 
        commandes c
    WHERE 
        {$whereClause} 
    GROUP BY c.transaction_id
    ORDER BY MAX(c.order_date) DESC
";

// --- 4. Exécution de la requête préparée ---
$stmt = $conn->prepare($query);

if (!$stmt) {
    send_error("Échec de la préparation de la requête: " . $conn->error);
}

// Bind des paramètres si il y en a (si $paramTypes n'est pas vide)
if ($paramTypes) {
    // La fonction `call_user_func_array` permet d'appeler `bind_param` avec le tableau dynamique de valeurs
    $stmt->bind_param($paramTypes, ...$paramValues);
}

// Exécution de l'instruction préparée
if (!$stmt->execute()) {
    send_error("Échec de l'exécution de la requête: " . $stmt->error);
}

$result = $stmt->get_result(); // Récupération du résultat
$orders = [];

// --- 5. Traitement des résultats ---
if ($result && $result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        // Le casting explicite est bon pour garantir les types dans la réponse JSON
        $row['total_price'] = (float) $row['total_price'];
        
        // Utilisation de l'opérateur de coalescence null (`??`) pour une écriture plus concise (même si ici c'est plus verbeux)
        $row['latitude'] = $row['latitude'] !== null ? (float) $row['latitude'] : null;
        $row['longitude'] = $row['longitude'] !== null ? (float) $row['longitude'] : null;

        $orders[] = $row;
    }
}

// --- 6. Nettoyage et réponse ---
$stmt->close();
$conn->close();

// Envoi de la réponse JSON finale
echo json_encode($orders);
?>