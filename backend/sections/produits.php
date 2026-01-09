<?php
// sections/produits.php - Gestion des Produits
if ($processing_post_only) {
    return; // Ne rien afficher si on traite uniquement le POST
}

// Clés API WooCommerce
$consumer_key = 'ck_20c9eaf44a30b5028558551525a1b24201ce8293';
$consumer_secret = 'cs_d2f987d16ac480a59f04a5fefdf563a269667ca3';
$api_url = 'https://www.babutik.com/wp-json/wc/v3/products?per_page=100';

// Préparation de l'authentification Basic
$credentials = base64_encode("$consumer_key:$consumer_secret");

// Initialisation de cURL
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $api_url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Authorization: Basic ' . $credentials
]);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true);
curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 2);

// Exécution de la requête
$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

$products = [];
$error_message = '';

if ($error) {
    $error_message = 'Erreur cURL: ' . $error;
} elseif ($httpCode == 200) {
    $products = json_decode($response, true);
    if (json_last_error() !== JSON_ERROR_NONE) {
        $error_message = 'Erreur de décodage JSON: ' . json_last_error_msg();
        $products = [];
    }
} else {
    $error_message = 'Erreur lors de la récupération des produits. Code HTTP: ' . $httpCode;
}

// Recherche
$search_query = $_GET['search'] ?? '';
$filtered_products = $products;

if (!empty($search_query)) {
    $filtered_products = array_filter($products, function($product) use ($search_query) {
        $name = strtolower($product['name'] ?? '');
        $sku = strtolower($product['sku'] ?? '');
        $search = strtolower($search_query);
        return strpos($name, $search) !== false || strpos($sku, $search) !== false;
    });
}
?>

<div class="page-header">
    <h1><i class="fas fa-box"></i> Tous les Produits</h1>
    <p>Gérez tous les produits de votre boutique</p>
</div>

<?php if ($error_message): ?>
    <div class="alert alert-danger">
        <i class="fas fa-exclamation-triangle"></i> <?php echo htmlspecialchars($error_message); ?>
    </div>
<?php endif; ?>

<div class="content-card">
    <div class="d-flex justify-content-between align-items-center mb-3">
        <h2>Liste des Produits (<?php echo count($filtered_products); ?>)</h2>
        <div class="d-flex gap-2">
            <form method="GET" action="" class="d-flex">
                <input type="hidden" name="section" value="produits">
                <input type="text" name="search" class="form-control" placeholder="Rechercher un produit..." 
                       value="<?php echo htmlspecialchars($search_query); ?>" style="width: 250px;">
                <button type="submit" class="btn btn-primary ms-2">
                    <i class="fas fa-search"></i> Rechercher
                </button>
                <?php if (!empty($search_query)): ?>
                    <a href="?section=produits" class="btn btn-secondary ms-2">
                        <i class="fas fa-times"></i> Effacer
                    </a>
                <?php endif; ?>
            </form>
            <a href="https://www.babutik.com/wp-admin/edit.php?post_type=product" target="_blank" class="btn btn-primary">
                <i class="fas fa-plus"></i> Ajouter un produit
            </a>
        </div>
    </div>

    <?php if (empty($filtered_products)): ?>
        <div class="alert alert-info">
            <i class="fas fa-info-circle"></i> 
            <?php if (!empty($search_query)): ?>
                Aucun produit trouvé pour "<?php echo htmlspecialchars($search_query); ?>"
            <?php else: ?>
                Aucun produit disponible.
            <?php endif; ?>
        </div>
    <?php else: ?>
        <div class="table-responsive">
            <table class="table table-hover">
                <thead>
                    <tr>
                        <th style="width: 80px;">Image</th>
                        <th>Nom</th>
                        <th>SKU</th>
                        <th>Prix</th>
                        <th>Stock</th>
                        <th>Catégories</th>
                        <th>Statut</th>
                        <th>Date</th>
                        <th style="width: 120px;">Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($filtered_products as $product): ?>
                        <?php
                        $imageUrl = 'https://via.placeholder.com/50/CCCCCC/000000?text=No+Img';
                        if (!empty($product['images']) && isset($product['images'][0]['src'])) {
                            $imageUrl = $product['images'][0]['src'];
                        }
                        
                        $categories = [];
                        if (!empty($product['categories'])) {
                            foreach ($product['categories'] as $cat) {
                                $categories[] = $cat['name'];
                            }
                        }
                        
                        $regular_price = $product['regular_price'] ?? '0.00';
                        $sale_price = $product['sale_price'] ?? '';
                        $stock_status = $product['stock_status'] ?? 'instock';
                        $stock_quantity = $product['stock_quantity'] ?? null;
                        $status = $product['status'] ?? 'publish';
                        $date_created = $product['date_created'] ?? '';
                        $formatted_date = '';
                        if ($date_created) {
                            $date = new DateTime($date_created);
                            $formatted_date = $date->format('d/m/Y H:i');
                        }
                        ?>
                        <tr>
                            <td>
                                <img src="<?php echo htmlspecialchars($imageUrl); ?>" 
                                     alt="<?php echo htmlspecialchars($product['name']); ?>"
                                     style="width: 50px; height: 50px; object-fit: cover; border-radius: 4px;"
                                     onerror="this.src='https://via.placeholder.com/50/CCCCCC/000000?text=No+Img'">
                            </td>
                            <td>
                                <strong><?php echo htmlspecialchars($product['name']); ?></strong>
                                <?php if (!empty($product['short_description'])): ?>
                                    <br><small class="text-muted"><?php echo htmlspecialchars(substr(strip_tags($product['short_description']), 0, 50)); ?>...</small>
                                <?php endif; ?>
                            </td>
                            <td>
                                <?php if (!empty($product['sku'])): ?>
                                    <code><?php echo htmlspecialchars($product['sku']); ?></code>
                                <?php else: ?>
                                    <span class="text-muted">-</span>
                                <?php endif; ?>
                            </td>
                            <td>
                                <?php if (!empty($sale_price)): ?>
                                    <span class="text-decoration-line-through text-muted"><?php echo number_format((float)$regular_price, 2, ',', ' '); ?> $</span>
                                    <br><strong class="text-danger"><?php echo number_format((float)$sale_price, 2, ',', ' '); ?> $</strong>
                                <?php else: ?>
                                    <strong><?php echo number_format((float)$regular_price, 2, ',', ' '); ?> $</strong>
                                <?php endif; ?>
                            </td>
                            <td>
                                <?php if ($stock_quantity !== null): ?>
                                    <span class="badge <?php echo $stock_quantity > 0 ? 'badge-success' : 'badge-danger'; ?>">
                                        <?php echo $stock_quantity; ?>
                                    </span>
                                <?php else: ?>
                                    <span class="badge <?php echo $stock_status === 'instock' ? 'badge-success' : 'badge-danger'; ?>">
                                        <?php echo $stock_status === 'instock' ? 'En stock' : 'Rupture'; ?>
                                    </span>
                                <?php endif; ?>
                            </td>
                            <td>
                                <?php if (!empty($categories)): ?>
                                    <?php foreach (array_slice($categories, 0, 2) as $cat): ?>
                                        <span class="badge badge-info"><?php echo htmlspecialchars($cat); ?></span>
                                    <?php endforeach; ?>
                                    <?php if (count($categories) > 2): ?>
                                        <span class="text-muted">+<?php echo count($categories) - 2; ?></span>
                                    <?php endif; ?>
                                <?php else: ?>
                                    <span class="text-muted">-</span>
                                <?php endif; ?>
                            </td>
                            <td>
                                <span class="badge <?php echo $status === 'publish' ? 'badge-success' : 'badge-warning'; ?>">
                                    <?php echo $status === 'publish' ? 'Publié' : ucfirst($status); ?>
                                </span>
                            </td>
                            <td>
                                <small><?php echo $formatted_date; ?></small>
                            </td>
                            <td>
                                <div class="btn-group" role="group">
                                    <a href="https://www.babutik.com/wp-admin/post.php?post=<?php echo $product['id']; ?>&action=edit" 
                                       target="_blank" 
                                       class="btn btn-sm btn-primary" 
                                       title="Modifier">
                                        <i class="fas fa-edit"></i>
                                    </a>
                                    <a href="<?php echo $product['permalink'] ?? '#'; ?>" 
                                       target="_blank" 
                                       class="btn btn-sm btn-info" 
                                       title="Voir">
                                        <i class="fas fa-eye"></i>
                                    </a>
                                </div>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    <?php endif; ?>
</div>

