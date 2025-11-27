<?php
// Utilisation du fichier de configuration centralisé
require_once __DIR__ . '/db_connection.php';
// La connexion $conn est déjà créée dans db_connection.php

header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST");
header("Access-Control-Allow-Headers: Content-Type");

// Gestion des requêtes GET (récupération des commentaires)
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    // Validation de l'ID produit
    if (!isset($_GET['product_id'])) {
        http_response_code(400);
        echo json_encode([
            "status" => "error",
            "message" => "Le paramètre product_id est requis"
        ]);
        exit;
    }

    $product_id = (int)$_GET['product_id'];

    if ($product_id <= 0) {
        http_response_code(400);
        echo json_encode([
            "status" => "error",
            "message" => "ID produit invalide"
        ]);
        exit;
    }

    // Requête préparée pour récupérer les commentaires
    $stmt = $conn->prepare("
        SELECT id, product_id, user_name, comment, rating, 
               DATE_FORMAT(created_at, '%d/%m/%Y à %H:%i') as formatted_date
        FROM comments 
        WHERE product_id = ?
        ORDER BY created_at DESC
    ");
    $stmt->bind_param("i", $product_id);
    $stmt->execute();
    $result = $stmt->get_result();

    $comments = [];
    while ($row = $result->fetch_assoc()) {
        $comments[] = [
            'id' => $row['id'],
            'product_id' => $row['product_id'],
            'user_name' => htmlspecialchars($row['user_name']),
            'comment' => htmlspecialchars($row['comment']),
            'rating' => (int)$row['rating'],
            'created_at' => $row['formatted_date']
        ];
    }

    echo json_encode($comments);
    $stmt->close();
}

// Gestion des requêtes POST (ajout de commentaire)
elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents("php://input"), true);

    // Validation des données JSON
    if (json_last_error() !== JSON_ERROR_NONE) {
        http_response_code(400);
        echo json_encode([
            "status" => "error",
            "message" => "Données JSON invalides"
        ]);
        exit;
    }

    $required_fields = ['product_id', 'user_name', 'comment', 'rating'];
    foreach ($required_fields as $field) {
        if (!isset($data[$field]) || empty($data[$field])) {
            http_response_code(400);
            echo json_encode([
                "status" => "error",
                "message" => "Le champ $field est requis"
            ]);
            exit;
        }
    }

    $product_id = (int)$data['product_id'];
    $user_name = trim($data['user_name']);
    $comment = trim($data['comment']);
    $rating = (int)$data['rating'];

    // Vérifications supplémentaires
    if ($product_id <= 0) {
        http_response_code(400);
        echo json_encode([
            "status" => "error",
            "message" => "ID produit invalide"
        ]);
        exit;
    }

    if (strlen($user_name) > 50) {
        http_response_code(400);
        echo json_encode([
            "status" => "error",
            "message" => "Le nom ne doit pas dépasser 50 caractères"
        ]);
        exit;
    }

    if (strlen($comment) > 500) {
        http_response_code(400);
        echo json_encode([
            "status" => "error",
            "message" => "Le commentaire ne doit pas dépasser 500 caractères"
        ]);
        exit;
    }

    if ($rating < 1 || $rating > 5) {
        http_response_code(400);
        echo json_encode([
            "status" => "error",
            "message" => "La note doit être entre 1 et 5"
        ]);
        exit;
    }

    // Insertion du commentaire
    $stmt = $conn->prepare("
        INSERT INTO comments (product_id, user_name, comment, rating) 
        VALUES (?, ?, ?, ?)
    ");
    $stmt->bind_param("issi", $product_id, $user_name, $comment, $rating);

    if ($stmt->execute()) {
        http_response_code(201);
        echo json_encode([
            "status" => "success",
            "message" => "Commentaire ajouté avec succès",
            "comment_id" => $stmt->insert_id
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            "status" => "error",
            "message" => "Échec de l'ajout du commentaire"
        ]);
    }

    $stmt->close();
}

// Méthode non autorisée
else {
    http_response_code(405);
    echo json_encode([
        "status" => "error",
        "message" => "Méthode non autorisée"
    ]);
}

$conn->close();
?>
