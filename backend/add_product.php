<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Ajouter un nouveau produit</title>
    <link rel="stylesheet" href="style.css">
    <style>
        /* Styles spécifiques au formulaire d'ajout */
        .form-group {
            margin-bottom: 15px;
        }

        .form-group label {
            display: block;
            margin-bottom: 5px;
            font-weight: bold;
            color: #333;
        }

        .form-group input[type="text"],
        .form-group input[type="number"],
        .form-group textarea,
        .form-group select {
            width: calc(100% - 22px); /* Ajuste pour le padding */
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 4px;
            font-size: 1em;
        }

        .form-group textarea {
            resize: vertical; /* Permet le redimensionnement vertical */
            min-height: 80px;
        }

        .form-group input[type="checkbox"] {
            margin-right: 5px;
            transform: scale(1.1);
        }

        .form-actions {
            margin-top: 25px;
            text-align: right;
        }

        .form-actions button {
            background-color: #007bff;
            color: white;
            padding: 12px 25px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 1.1em;
            transition: background-color 0.3s ease;
        }

        .form-actions button:hover {
            background-color: #0056b3;
        }

        /* Message de succès/erreur */
        .success-message {
            background-color: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
            padding: 15px;
            margin-bottom: 20px;
            border-radius: 5px;
            text-align: center;
        }

        .error-message {
            background-color: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
            padding: 15px;
            margin-bottom: 20px;
            border-radius: 5px;
            text-align: center;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Ajouter un nouveau produit</h1>
        <p>Veuillez remplir les informations ci-dessous pour ajouter un produit à votre boutique.</p>

        <?php
        // Inclure le fichier de configuration sécurisé si vous l'avez créé
        // include_once 'config.php'; // Décommentez si vous utilisez un fichier config.php

        // Vos clés d'API WooCommerce
        $consumer_key = defined('WC_CONSUMER_KEY') ? WC_CONSUMER_KEY : 'ck_ad48e33210f0327f5126c4bb84d79ba833080d52';
        $consumer_secret = defined('WC_CONSUMER_SECRET') ? WC_CONSUMER_SECRET : 'cs_2ec17813a81fb24e2ef4029223cc8e45f3764e0a';
        $api_base_url = defined('WC_API_URL') ? WC_API_URL : 'https://www.babutik.com/wp-json/wc/v3';
        $api_products_endpoint = $api_base_url . '/products';

        $message = '';
        $message_type = '';

        // Vérifier si le formulaire a été soumis
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            // 1. Récupérer et nettoyer les données du formulaire
            $name = htmlspecialchars(trim($_POST['name'] ?? ''));
            $price = htmlspecialchars(trim($_POST['price'] ?? ''));
            $regular_price = htmlspecialchars(trim($_POST['regular_price'] ?? ''));
            $sale_price = htmlspecialchars(trim($_POST['sale_price'] ?? ''));
            $description = htmlspecialchars(trim($_POST['description'] ?? ''));
            $short_description = htmlspecialchars(trim($_POST['short_description'] ?? ''));
            $image_url = htmlspecialchars(trim($_POST['image_url'] ?? ''));
            $sku = htmlspecialchars(trim($_POST['sku'] ?? ''));
            $stock_quantity = filter_var($_POST['stock_quantity'] ?? null, FILTER_VALIDATE_INT);
            $stock_status = htmlspecialchars(trim($_POST['stock_status'] ?? 'instock'));
            $manage_stock = isset($_POST['manage_stock']) ? true : false;
            $status = htmlspecialchars(trim($_POST['status'] ?? 'publish'));
            $categories_input = htmlspecialchars(trim($_POST['categories'] ?? '')); // Exemple: "T-shirts,Accessoires"
            $tags_input = htmlspecialchars(trim($_POST['tags'] ?? '')); // Exemple: "Coton,Nouveau"


            // 2. Validation basique (peut être étendue)
            if (empty($name)) {
                $message = 'Le nom du produit est requis.';
                $message_type = 'error';
            } elseif (empty($regular_price) && empty($price)) { // Au moins un prix doit être défini
                 $message = 'Le prix régulier ou le prix doit être défini.';
                 $message_type = 'error';
            } else {
                // Préparation des données pour l'API
                $product_data = [
                    'name' => $name,
                    'type' => 'simple', // Type de produit simple par défaut
                    'status' => $status,
                    'description' => $description,
                    'short_description' => $short_description,
                    'sku' => $sku,
                    'manage_stock' => $manage_stock,
                    'stock_status' => $stock_status,
                ];

                if ($manage_stock && $stock_quantity !== null) {
                    $product_data['stock_quantity'] = $stock_quantity;
                }

                // Prix
                if (!empty($regular_price)) {
                    $product_data['regular_price'] = $regular_price;
                }
                if (!empty($sale_price)) {
                    $product_data['sale_price'] = $sale_price;
                } elseif (!empty($price)) { // Si sale_price est vide mais price est là, utiliser price comme prix régulier
                    $product_data['regular_price'] = $price;
                }

                // Images
                if (!empty($image_url)) {
                    $product_data['images'] = [
                        ['src' => $image_url]
                    ];
                }

                // Catégories (nécessite les IDs ou de les créer si elles n'existent pas)
                // Pour cet exemple simple, nous allons supposer que vous entrez des noms de catégorie existants.
                // En réalité, il faudrait d'abord récupérer les catégories existantes ou gérer la création.
                $categories_array = [];
                if (!empty($categories_input)) {
                    $category_names = array_map('trim', explode(',', $categories_input));
                    foreach ($category_names as $cat_name) {
                        if (!empty($cat_name)) {
                            // Ici, vous auriez besoin d'une logique pour mapper le nom à un ID de catégorie
                            // Ou de créer la catégorie si elle n'existe pas.
                            // Pour simplifier, on envoie juste le nom pour voir si l'API peut le gérer ou attend un ID.
                            // Normalement, l'API attend ['id' => X]
                            // Pour un exemple fonctionnel simple, nous allons mettre un ID fictif ou laisser vide si non trouvé
                            // Ou mieux, on suppose qu'elles existent et on va créer un exemple pour "Accessoires" (ID 15)
                            // OU mieux, on va chercher l'ID de la catégorie par son nom (plus complexe pour cet exemple direct)
                            // Pour simplifier l'envoi vers l'API sans avoir à chercher l'ID,
                            // nous allons juste passer un exemple d'ID si le nom correspond
                            // C'est une simplification pour l'exemple.
                            if (strtolower($cat_name) == 'accessoires') {
                                $categories_array[] = ['id' => 15]; // Exemple ID pour "Accessoires"
                            } elseif (strtolower($cat_name) == 't-shirts') {
                                $categories_array[] = ['id' => 16]; // Exemple ID pour "T-Shirts"
                            } else {
                                // Si la catégorie n'est pas connue/mappée, l'ignorer ou gérer l'erreur
                                // Pour une vraie application, vous feriez une requête GET pour trouver l'ID
                                // ou une requête POST pour créer la catégorie si elle n'existe pas.
                            }
                        }
                    }
                }
                if (!empty($categories_array)) {
                    $product_data['categories'] = $categories_array;
                } else {
                     // Si aucune catégorie valide n'est trouvée, WooCommerce peut assigner une catégorie par défaut ou non.
                     // On peut aussi explicitement ajouter une catégorie par défaut si besoin.
                     $product_data['categories'] = [['id' => 15]]; // Example: Default to 'Accessoires'
                }


                // Tags (similaire aux catégories, nécessite les IDs)
                $tags_array = [];
                if (!empty($tags_input)) {
                    $tag_names = array_map('trim', explode(',', $tags_input));
                    foreach ($tag_names as $tag_name) {
                         if (!empty($tag_name)) {
                            // Ici, vous feriez une recherche ou une création de tag par son nom
                            // Pour simplifier, nous allons juste envoyer un exemple d'ID si le nom correspond
                             if (strtolower($tag_name) == 'coton') {
                                 $tags_array[] = ['id' => 17]; // Exemple ID pour "Coton"
                             }
                         }
                    }
                }
                if (!empty($tags_array)) {
                    $product_data['tags'] = $tags_array;
                }


                // 3. Envoyer les données à l'API WooCommerce
                $ch = curl_init();
                curl_setopt($ch, CURLOPT_URL, $api_products_endpoint);
                curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
                curl_setopt($ch, CURLOPT_POST, true); // Indique que c'est une requête POST
                curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($product_data)); // Envoie les données en JSON
                curl_setopt($ch, CURLOPT_HTTPHEADER, [
                    'Content-Type: application/json',
                    'Authorization: Basic ' . base64_encode("$consumer_key:$consumer_secret")
                ]);
                curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true);
                curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 2);

                $response = curl_exec($ch);
                $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
                curl_close($ch);

                if (curl_errno($ch)) {
                    $message = 'Erreur cURL lors de l\'envoi: ' . curl_error($ch);
                    $message_type = 'error';
                } elseif ($httpCode == 201) { // Code 201 Created pour un ajout réussi
                    $message = 'Produit ajouté avec succès !';
                    $message_type = 'success';
                    // Optionnel: Vider le formulaire après succès ou rediriger
                    // header('Location: index.php?status=product_added'); exit();
                } else {
                    $decoded_response = json_decode($response, true);
                    $error_details = 'Une erreur est survenue lors de l\'ajout du produit.';
                    if (isset($decoded_response['message'])) {
                        $error_details .= ' Détails: ' . $decoded_response['message'];
                    }
                    $message = 'Erreur (' . $httpCode . '): ' . $error_details;
                    $message_type = 'error';
                    // Pour le débogage, afficher la réponse complète de l'API:
                    // echo '<pre>' . htmlspecialchars($response) . '</pre>';
                }
            }
        }
        ?>

        <?php if ($message): ?>
            <p class="<?php echo $message_type; ?>-message"><?php echo $message; ?></p>
        <?php endif; ?>

        <form action="add_product.php" method="POST">
            <div class="form-group">
                <label for="name">Nom du produit: <span style="color:red;">*</span></label>
                <input type="text" id="name" name="name" required value="<?php echo htmlspecialchars($_POST['name'] ?? ''); ?>">
            </div>

            <div class="form-group">
                <label for="regular_price">Prix régulier: <span style="color:red;">*</span></label>
                <input type="number" id="regular_price" name="regular_price" step="0.01" min="0" required value="<?php echo htmlspecialchars($_POST['regular_price'] ?? ''); ?>">
            </div>

            <div class="form-group">
                <label for="sale_price">Prix promo (optionnel):</label>
                <input type="number" id="sale_price" name="sale_price" step="0.01" min="0" value="<?php echo htmlspecialchars($_POST['sale_price'] ?? ''); ?>">
            </div>

            <div class="form-group">
                <label for="short_description">Courte description:</label>
                <textarea id="short_description" name="short_description"><?php echo htmlspecialchars($_POST['short_description'] ?? ''); ?></textarea>
            </div>

            <div class="form-group">
                <label for="description">Description complète:</label>
                <textarea id="description" name="description"><?php echo htmlspecialchars($_POST['description'] ?? ''); ?></textarea>
            </div>

            <div class="form-group">
                <label for="sku">UGS (Code Produit Unique):</label>
                <input type="text" id="sku" name="sku" value="<?php echo htmlspecialchars($_POST['sku'] ?? ''); ?>">
            </div>

            <div class="form-group">
                <input type="checkbox" id="manage_stock" name="manage_stock" <?php echo (isset($_POST['manage_stock']) && $_POST['manage_stock']) ? 'checked' : ''; ?>>
                <label for="manage_stock" style="display:inline;">Gérer le stock</label>
            </div>

            <div class="form-group">
                <label for="stock_quantity">Quantité en stock:</label>
                <input type="number" id="stock_quantity" name="stock_quantity" min="0" value="<?php echo htmlspecialchars($_POST['stock_quantity'] ?? ''); ?>">
            </div>

            <div class="form-group">
                <label for="stock_status">Statut du stock:</label>
                <select id="stock_status" name="stock_status">
                    <option value="instock" <?php echo (($_POST['stock_status'] ?? 'instock') == 'instock') ? 'selected' : ''; ?>>En stock</option>
                    <option value="outofstock" <?php echo (($_POST['stock_status'] ?? '') == 'outofstock') ? 'selected' : ''; ?>>Rupture de stock</option>
                    <option value="onbackorder" <?php echo (($_POST['stock_status'] ?? '') == 'onbackorder') ? 'selected' : ''; ?>>En précommande</option>
                </select>
            </div>

            <div class="form-group">
                <label for="categories">Catégories (séparées par des virgules, ex: Accessoires,T-shirts):</label>
                <input type="text" id="categories" name="categories" placeholder="Accessoires, T-shirts" value="<?php echo htmlspecialchars($_POST['categories'] ?? ''); ?>">
                <small>Note: Pour cet exemple, "Accessoires" (ID 15) et "T-shirts" (ID 16) sont gérés par ID. D'autres catégories nécessitent une récupération préalable de leur ID.</small>
            </div>

            <div class="form-group">
                <label for="tags">Étiquettes (séparées par des virgules, ex: Coton,Nouveau):</label>
                <input type="text" id="tags" name="tags" placeholder="Coton, Nouveau" value="<?php echo htmlspecialchars($_POST['tags'] ?? ''); ?>">
                <small>Note: Pour cet exemple, "Coton" (ID 17) est géré par ID. D'autres étiquettes nécessitent une récupération préalable de leur ID.</small>
            </div>

            <div class="form-group">
                <label for="image_url">URL de l'image principale:</label>
                <input type="text" id="image_url" name="image_url" placeholder="https://exemple.com/image.jpg" value="<?php echo htmlspecialchars($_POST['image_url'] ?? ''); ?>">
            </div>

            <div class="form-group">
                <label for="status">Statut du produit:</label>
                <select id="status" name="status">
                    <option value="publish" <?php echo (($_POST['status'] ?? 'publish') == 'publish') ? 'selected' : ''; ?>>Publié</option>
                    <option value="pending" <?php echo (($_POST['status'] ?? '') == 'pending') ? 'selected' : ''; ?>>En attente</option>
                    <option value="draft" <?php echo (($_POST['status'] ?? '') == 'draft') ? 'selected' : ''; ?>>Brouillon</option>
                </select>
            </div>

            <div class="form-actions">
                <a href="index.php" class="add-product-button" style="background-color: #6c757d; margin-right: 10px;">Annuler et Retour</a>
                <button type="submit">Ajouter le produit</button>
            </div>
        </form>
    </div>
</body>
</html>