<?php
// --- CORS Headers ---
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *'); // IMPORTANT: Change * to your specific frontend domain(s) in production
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// --- Database Configuration ---
// Utilisation du fichier de configuration centralisé
require_once __DIR__ . '/db_connection.php';
// La connexion PDO $pdo est déjà créée dans db_connection.php

try {
    // Utilisation de la connexion PDO centralisée
    $conn = $pdo;

    // Get username from query parameter.
    $filterUsername = isset($_GET['username']) ? trim($_GET['username']) : null;

    // Base SQL Query avec informations du livreur
    $sql = "
        SELECT
            c.id,
            c.name,
            c.address,
            c.transaction_id,
            DATE_FORMAT(c.order_date, '%Y-%m-%d %H:%i:%s') as order_date,
            c.product_name,
            c.quantity,
            c.payment_method,
            c.total_price, -- This total_price is for the individual product line from the DB
            c.status,      -- We retrieve the status here
            c.livreur_id,
            l.nom as livreur_nom,
            l.prenom as livreur_prenom,
            l.telephone as livreur_telephone,
            l.email as livreur_email,
            l.note_moyenne as livreur_note_moyenne
        FROM commandes c
        LEFT JOIN livreurs l ON c.livreur_id = l.id
    ";

    // Add WHERE clause if a username filter is provided
    if ($filterUsername) {
        $sql .= " WHERE c.name = :username";
    }

    $sql .= " ORDER BY c.transaction_id DESC, c.order_date DESC"; // Order by transaction_id to keep groups together, then by date

    $stmt = $conn->prepare($sql);

    // Bind parameter if a username filter is active
    if ($filterUsername) {
        $stmt->bindParam(':username', $filterUsername, PDO::PARAM_STR);
    }

    $stmt->execute();
    $commandes = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // --- Grouping by transaction_id and calculating total price ---
    $groupedOrders = [];
    foreach ($commandes as $cmd) {
        $txId = $cmd['transaction_id'];
        $lineItemTotalPrice = (float)$cmd['total_price']; // Ensure it's a float for summation

        // If this transaction_id hasn't been added yet, initialize its entry
        if (!isset($groupedOrders[$txId])) {
            $groupedOrders[$txId] = [
                'id' => $cmd['id'], // Assuming 'id' here is the order's primary ID (or first one for the transaction)
                'name' => $cmd['name'],
                'address' => $cmd['address'],
                'transaction_id' => $cmd['transaction_id'],
                'order_date' => $cmd['order_date'],
                'payment_method' => $cmd['payment_method'],
                'total_price' => 0.0, // Initialize total_price for the entire order to 0
                'status' => $cmd['status'], // Assign the status from the database
                'productList' => [], // Initialize product list for this transaction
                // 💡 NOUVEAU : Informations du livreur
                'livreur_id' => $cmd['livreur_id'] ?? null,
                'livreur_nom' => $cmd['livreur_nom'] ?? null,
                'livreur_prenom' => $cmd['livreur_prenom'] ?? null,
                'livreur_telephone' => $cmd['livreur_telephone'] ?? null,
                'livreur_email' => $cmd['livreur_email'] ?? null,
                'livreur_note_moyenne' => $cmd['livreur_note_moyenne'] ?? null,
            ];
        }

        // Add the current line item's total_price to the overall order total
        $groupedOrders[$txId]['total_price'] += $lineItemTotalPrice;

        // Add product details to the productList for the current transaction
        $groupedOrders[$txId]['productList'][] = [
            'product_name' => $cmd['product_name'],
            'quantity' => (int)$cmd['quantity'],
            'total_price' => round($lineItemTotalPrice, 2) // This total_price is for the individual product line
        ];
    }

    // Round the final aggregated total_price for each order
    foreach ($groupedOrders as $txId => $order) {
        $groupedOrders[$txId]['total_price'] = round($order['total_price'], 2);
    }

    // Convert the associative array back to a simple indexed array for JSON output
    $result = array_values($groupedOrders);

    // Send success response
    echo json_encode([
        'status' => 'success',
        'data' => $result
    ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);

} catch (PDOException $e) {
    // Send error response
    http_response_code(500); // Internal Server Error
    echo json_encode([
        'status' => 'error',
        'message' => 'Erreur serveur: ' . $e->getMessage()
    ], JSON_PRETTY_PRINT);
} finally {
    // Close the database connection
    $conn = null;
}
?>