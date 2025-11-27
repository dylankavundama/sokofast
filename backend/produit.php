<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Administration Produits Soko fast</title>
    <link rel="stylesheet" href="style.css">
    <style>
        /* Styles spécifiques pour le tableau (could be moved to style.css) */
        table {
            width: 100%;
            border-collapse: collapse; /* Supprime l'espace entre les bordures de cellules */
            margin-top: 20px;
            background-color: #fff;
            box-shadow: 0 2px 8px rgba(0,0,0,0.05);
            border-radius: 8px;
            overflow: hidden; /* Pour que les coins arrondis fonctionnent avec les bordures */
        }

        th, td {
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid #eee; /* Ligne de séparation */
            vertical-align: middle; /* Alignement vertical */
        }

        th {
            background-color: #f8f8f8;
            color: #555;
            font-weight: 600;
            text-transform: uppercase;
            font-size: 0.9em;
            position: sticky;
            top: 0; /* Pour les en-têtes collants si le tableau est scrollable */
        }

        tr:hover {
            background-color: #f5f5f5; /* Survol des lignes */
        }

        td.product-cell {
            display: flex;
            align-items: center;
            gap: 10px; /* Espace entre image et texte */
        }

        td.product-cell img {
            width: 50px;
            height: 50px;
            object-fit: cover;
            border-radius: 4px;
            flex-shrink: 0;
        }

        .product-name-links {
            display: flex;
            flex-direction: column;
        }

        .product-name-links strong {
            color: #0073aa; /* Couleur de lien WordPress */
            font-weight: 500;
            font-size: 1.1em;
        }

        .product-actions {
            font-size: 0.8em;
            color: #777;
            margin-top: 5px;
        }

        .product-actions a {
            color: #0073aa;
            text-decoration: none;
            margin-right: 8px;
            transition: color 0.2s ease;
        }
        .product-actions a:hover {
            color: #005177;
            text-decoration: underline;
        }
        .product-actions .delete-link {
            color: #a00; /* Rouge pour "Corbeille" */
        }
        .product-actions .delete-link:hover {
            color: #e00;
        }

        .price-display {
            font-weight: bold;
            color: #333;
        }
        .regular-price {
            text-decoration: line-through;
            color: #777;
            font-size: 0.9em;
            margin-right: 5px;
        }
        .sale-price {
            color: #dc3545; /* Rouge pour le prix promo */
        }

        .stock-status-cell {
            font-weight: bold;
        }
        .in-stock {
            color: #28a745; /* Vert */
        }
        .out-of-stock {
            color: #dc3545; /* Rouge */
        }
        .on-backorder {
            color: #ffc107; /* Jaune/orange */
        }
        .stock-quantity {
            font-size: 0.85em;
            color: #555;
        }

        .category-list, .tag-list {
            font-size: 0.9em;
            color: #555;
        }
        .category-list a, .tag-list a {
            color: #0073aa;
            text-decoration: none;
        }
        .category-list a:hover, .tag-list a:hover {
            text-decoration: underline;
        }

        .date-cell {
            font-size: 0.9em;
            color: #777;
        }

        /* Checkbox styling (basic) */
        input[type="checkbox"] {
            transform: scale(1.2); /* Make checkbox a bit bigger */
            margin-right: 5px;
        }

        /* Responsive adjustments for tables */
        @media (max-width: 900px) {
            table, thead, tbody, th, td, tr {
                display: block; /* Force table elements to stack */
            }

            thead tr {
                position: absolute;
                top: -9999px; /* Hide table headers visually */
                left: -9999px;
            }

            tr {
                border: 1px solid #ddd;
                margin-bottom: 15px;
                border-radius: 8px;
                box-shadow: 0 2px 5px rgba(0,0,0,0.05);
            }

            td {
                border: none; /* Remove inner cell borders */
                position: relative;
                padding-left: 50%; /* Make space for the label */
                text-align: right;
            }

            td:before {
                content: attr(data-label); /* Use data-label for the label */
                position: absolute;
                left: 6px;
                width: 45%;
                padding-right: 10px;
                white-space: nowrap;
                text-align: left;
                font-weight: bold;
                color: #333;
            }

            td.product-cell {
                flex-direction: column; /* Stack image and text on small screens */
                align-items: flex-start;
                padding-left: 6px; /* Adjust padding for first cell */
                text-align: left;
            }
            td.product-cell:before {
                content: none; /* No label for the first cell */
            }
        }

        /* Add general container styles from previous style.css to match theme */
        .container {
            width: 95%; /* Légèrement plus large */
            max-width: 1300px; /* Plus large pour la table */
            margin: 20px auto;
            padding: 25px;
            background-color: #fff;
            box-shadow: 0 4px 15px rgba(0, 0, 0, 0.08); /* Ombre plus douce */
            border-radius: 10px;
        }

        h1 {
            text-align: center;
            color: #2c3e50; /* Bleu foncé */
            margin-bottom: 30px;
            font-size: 2.2em;
            font-weight: 600;
        }

        .add-product-button {
            display: inline-block; /* Changed to inline-block for better placement near table */
            background-color: #27ae60;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 6px;
            text-decoration: none;
            font-size: 16px;
            font-weight: 500;
            transition: background-color 0.3s ease, transform 0.2s ease;
            text-align: center;
            margin-bottom: 20px; /* Space below button */
        }

        .add-product-button:hover {
            background-color: #229a53;
            transform: translateY(-2px);
        }

        .error-message, .warning-message {
            color: #c0392b;
            background-color: #fbecec;
            border: 1px solid #e74c3c;
            padding: 12px;
            margin-bottom: 25px;
            border-radius: 6px;
            text-align: center;
            font-weight: bold;
        }
        .warning-message {
            color: #e67e22;
            background-color: #fdf5e6;
            border: 1px solid #f39c12;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Administration Produits</h1>

        <a href="https://babutik.com/wp-admin/edit.php?post_type=product" class="add-product-button">Ajouter un nouveau produit</a>

        <?php if (!defined('WC_CONSUMER_KEY') || !defined('WC_CONSUMER_SECRET')): ?>
            <p class="warning-message">
                Attention: Les clés API sont codées en dur dans ce fichier. Pour la production, utilisez un fichier de configuration sécurisé.
            </p>
        <?php endif; ?>

        <?php
        // Inclure le fichier de configuration sécurisé si vous l'avez créé
        // include_once 'config.php'; // Décommentez si vous utilisez un fichier config.php

        // Vos clés d'API WooCommerce
        $consumer_key = defined('WC_CONSUMER_KEY') ? WC_CONSUMER_KEY : 'ck_ad48e33210f0327f5126c4bb84d79ba833080d52';
        $consumer_secret = defined('WC_CONSUMER_SECRET') ? WC_CONSUMER_SECRET : 'cs_2ec17813a81fb24e2ef4029223cc8e45f3764e0a';
        $api_url = defined('WC_API_URL') ? WC_API_URL . '?per_page=100' : 'https://www.babutik.com/wp-json/wc/v3/products?per_page=100';

        // Préparation de l'authentification Basic
        $credentials = base64_encode("$consumer_key:$consumer_secret");

        // Initialisation de cURL
        $ch = curl_init();

        // Configuration des options cURL
        curl_setopt($ch, CURLOPT_URL, $api_url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Authorization: Basic ' . $credentials
        ]);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true);
        curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 2);

        // Exécution de la requête cURL
        $response = curl_exec($ch);

        // Vérification des erreurs cURL
        if (curl_errno($ch)) {
            $errorMessage = 'Erreur cURL: ' . curl_error($ch);
            echo '<p class="error-message">' . $errorMessage . '</p>';
            $products = [];
        } else {
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);

            if ($httpCode == 200) {
                $products = json_decode($response, true);
                if (json_last_error() !== JSON_ERROR_NONE) {
                    echo '<p class="error-message">Erreur de décodage JSON: ' . json_last_error_msg() . '</p>';
                    $products = [];
                }
            } else {
                echo '<p class="error-message">Erreur lors de la récupération des produits. Code HTTP: ' . $httpCode . '</p>';
                echo '<pre>' . htmlspecialchars($response) . '</pre>';
                $products = [];
            }
        }

        if (!empty($products)) {
            echo '<table>';
            echo '<thead>';
            echo '<tr>';
            echo '<th><input type="checkbox" aria-label="Sélectionner tout"></th>'; // Checkbox pour sélectionner tout
            echo '<th>Nom</th>';
            echo '<th>UGS</th>';
            echo '<th>Stock</th>';
            echo '<th>Prix</th>';
            echo '<th>Catégories</th>';
            echo '<th>Étiquettes</th>';
            echo '<th>Date</th>';
            echo '</tr>';
            echo '</thead>';
            echo '<tbody>';

            foreach ($products as $product) {
                $imageUrl = 'https://via.placeholder.com/50/CCCCCC/000000?text=No+Img'; // Petite image par défaut
                if (!empty($product['images']) && isset($product['images'][0]['src'])) {
                    $imageUrl = $product['images'][0]['src'];
                }

                // Catégories
                $categories = [];
                if (!empty($product['categories'])) {
                    foreach ($product['categories'] as $cat) {
                        $categories[] = '<a href="#">' . htmlspecialchars($cat['name']) . '</a>'; // Lien vers la catégorie (placeholder)
                    }
                }
                $category_names = !empty($categories) ? implode(', ', $categories) : '<span style="color:#aaa;">Non catégorisé</span>';

                // Étiquettes (Tags) - WooCommerce API v3 'tags' field
                $tags = [];
                if (!empty($product['tags'])) {
                    foreach ($product['tags'] as $tag) {
                        $tags[] = '<a href="#">' . htmlspecialchars($tag['name']) . '</a>'; // Lien vers le tag (placeholder)
                    }
                }
                $tag_names = !empty($tags) ? implode(', ', $tags) : '<span style="color:#aaa;">—</span>'; // Afficher un tiret si vide

                // Stock
                $stock_info = '';
                $stock_class = '';
                if (isset($product['stock_status'])) {
                    if ($product['stock_status'] == 'instock') {
                        $stock_info = 'En stock';
                        $stock_class = 'in-stock';
                        if (isset($product['stock_quantity']) && $product['stock_quantity'] !== null) {
                            $stock_info .= '<br><span class="stock-quantity">(' . $product['stock_quantity'] . ' disponibles)</span>';
                        }
                    } elseif ($product['stock_status'] == 'outofstock') {
                        $stock_info = 'Rupture de stock';
                        $stock_class = 'out-of-stock';
                    } elseif ($product['stock_status'] == 'onbackorder') {
                        $stock_info = 'En précommande';
                        $stock_class = 'on-backorder';
                    } else {
                        $stock_info = ucfirst($product['stock_status']);
                    }
                } else {
                    $stock_info = 'N/A';
                }

                // Prix
                $price_display = '';
                if (!empty($product['sale_price'])) {
                    $price_display .= '<span class="regular-price">' . htmlspecialchars($product['regular_price']) . ' €</span>';
                    $price_display .= '<span class="sale-price">' . htmlspecialchars($product['sale_price']) . ' €</span>';
                } elseif (!empty($product['price'])) {
                    $price_display .= '<span class="price-display">' . htmlspecialchars($product['price']) . ' €</span>';
                } else {
                    $price_display .= '<span class="price-display">Gratuit</span>'; // Ou 'N/A' si non applicable
                }

                // Date de publication
                $date_published = 'N/A';
                if (!empty($product['date_published_gmt'])) {
                    try {
                        $datetime = new DateTime($product['date_published_gmt']);
                        $date_published = 'Publié<br>' . $datetime->format('d/m/Y') . ' à ' . $datetime->format('H\hi');
                    } catch (Exception $e) {
                        // Handle date parsing error
                    }
                }

                echo '<tr>';
                echo '<td><input type="checkbox" aria-label="Sélectionner produit ' . htmlspecialchars($product['name'] ?? '') . '"></td>';
                echo '<td class="product-cell" data-label="Nom">'; // data-label for responsive
                echo '<img src="' . htmlspecialchars($imageUrl) . '" alt="' . htmlspecialchars($product['name'] ?? 'Nom inconnu') . '">';
                echo '<div class="product-name-links">';
                echo '<strong>' . htmlspecialchars($product['name'] ?? 'Produit sans nom') . '</strong>';
                echo '<div class="product-actions">';
                echo '<a href="#">Modifier</a> | '; // Placeholder link
                echo '<a href="#">Modification rapide</a> | '; // Placeholder link
                echo '<a href="#" class="delete-link">Corbeille</a> | '; // Placeholder link
                echo '<a href="#">Voir</a> | '; // Placeholder link
                echo '<a href="#">Dupliquer</a>'; // Placeholder link
                echo '</div>';
                echo '</div>';
                echo '</td>';
                echo '<td data-label="UGS">' . htmlspecialchars($product['sku'] ?? '—') . '</td>'; // SKU (UGS)
                echo '<td class="stock-status-cell ' . $stock_class . '" data-label="Stock">' . $stock_info . '</td>';
                echo '<td data-label="Prix">' . $price_display . '</td>';
                echo '<td class="category-list" data-label="Catégories">' . $category_names . '</td>';
                echo '<td class="tag-list" data-label="Étiquettes">' . $tag_names . '</td>'; // Tags (Étiquettes)
                echo '<td class="date-cell" data-label="Date">' . $date_published . '</td>';
                echo '</tr>';
            }

            echo '</tbody>';
            echo '</table>';
        } else {
            echo '<p>Aucun produit disponible pour le moment ou une erreur est survenue lors du chargement.</p>';
        }
        ?>
    </div>
</body>
</html>