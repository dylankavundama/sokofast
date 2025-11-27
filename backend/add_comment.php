<?php
// 1. CORS Headers: Essential for allowing frontend (e.g., JavaScript) requests from different origins.
//    IMPORTANT: In a production environment, replace '*' with your frontend's specific domain (e.g., 'https://your-frontend-domain.com')
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS"); // Add other methods if your frontend uses them
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Handle preflight requests (OPTIONS method sent by browsers before the actual request)
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200); // Respond with 200 OK for preflight
    exit();
}

// Set content type for JSON response
header('Content-Type: application/json');

// 2. Database Connection Details
// Utilisation du fichier de configuration centralisé
require_once __DIR__ . '/db_connection.php';
// La connexion $conn est déjà créée dans db_connection.php

// Initialize response array
$response = ["status" => "error", "message" => "An unknown error occurred."];

// 3. Error Reporting (Production: errors logged, not displayed)
ini_set('display_errors', 0); // Désactivé en production pour sécurité
ini_set('log_errors', 1); // Les erreurs sont loggées
ini_set('display_startup_errors', 0);
error_reporting(E_ALL); // Toutes les erreurs sont reportées mais loggées uniquement

try {
    // La connexion $conn est déjà disponible depuis db_connection.php
    // La connexion est déjà vérifiée dans db_connection.php, pas besoin de vérifier à nouveau

    // Get JSON input and perform basic validation
    $json_input = file_get_contents("php://input");
    if (empty($json_input)) {
        throw new Exception("No data received.");
    }

    $data = json_decode($json_input);

    // Check if JSON decoding was successful and all required data properties exist
    if ($data === null) {
        throw new Exception("Invalid JSON data received.");
    }
    if (!isset($data->product_id) || !isset($data->user_name) || !isset($data->comment) || !isset($data->rating)) {
        throw new Exception("Missing required data fields.");
    }

    // Validate data types and values
    if (!is_numeric($data->product_id) || $data->product_id <= 0) {
        throw new Exception("Invalid product_id. Must be a positive number.");
    }
    if (!is_string($data->user_name) || empty(trim($data->user_name))) {
        throw new Exception("Invalid user_name. Cannot be empty.");
    }
    if (!is_string($data->comment) || empty(trim($data->comment))) {
        throw new Exception("Invalid comment. Cannot be empty.");
    }
    if (!is_numeric($data->rating) || $data->rating < 1 || $data->rating > 5) { // Assuming rating is 1-5
        throw new Exception("Invalid rating. Must be between 1 and 5.");
    }

    // Prepare the SQL statement using a prepared statement for security
    // **** THIS IS THE CORRECTED LINE ****
    $stmt = $conn->prepare("INSERT INTO comments (product_id, user_name, comment, rating) VALUES (?, ?, ?, ?)");

    if ($stmt === false) {
        throw new Exception("Failed to prepare statement: " . $conn->error);
    }

    // Bind parameters to the statement
    // "issi" stands for: integer, string, string, integer
    $stmt->bind_param("issi",
        $data->product_id,
        $data->user_name,
        $data->comment,
        $data->rating
    );

    // Execute the statement
    if ($stmt->execute()) {
        $response = ["status" => "success", "message" => "Comment added successfully."];
    } else {
        throw new Exception("Failed to execute statement: " . $stmt->error);
    }

    $stmt->close(); // Close the statement

} catch (Exception $e) {
    // Catch any exceptions and set the error response
    $response = ["status" => "error", "message" => $e->getMessage()];
    // For debugging, you might log the error: error_log("Error: " . $e->getMessage());
} finally {
    // Always close the database connection if it was successfully opened
    if ($conn && $conn instanceof mysqli) {
        $conn->close();
    }
    echo json_encode($response); // Always return a JSON response
}
?>