<?php
// commandes.php - Gestion des commandes

// 💡 NOUVEAU : Inclure la fonction de notification WhatsApp
require_once __DIR__ . '/../whatsapp_notification.php';

// Traitement de la mise à jour de statut
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['update_status'])) {
    if (!isset($_POST['csrf_token']) || $_POST['csrf_token'] !== $_SESSION['csrf_token']) {
        $error = "Erreur de sécurité : Jeton CSRF invalide.";
    } else {
        $id = filter_input(INPUT_POST, 'id', FILTER_VALIDATE_INT);
        $new_status = filter_input(INPUT_POST, 'new_status', FILTER_SANITIZE_STRING);
        $valid_statuses = ['annuler', 'en cours', 'terminer', 'PENDING', 'CONFIRMED', 'FAILED', 'EN_COURS', 'TERMINER', 'ANNULER'];
        
        if ($id && in_array($new_status, $valid_statuses)) {
            $stmt = $conn->prepare("UPDATE commandes SET status = ? WHERE id = ?");
            $stmt->bind_param("si", $new_status, $id);
            if ($stmt->execute()) {
                // 💡 NOUVEAU : Envoyer une notification WhatsApp au client
                $whatsappResult = notifyClientViaWhatsApp($conn, $id, $new_status);
                
                if ($whatsappResult['success'] && isset($whatsappResult['whatsapp_url'])) {
                    $message = "Statut de la commande #{$id} mis à jour avec succès. ";
                    $message .= "Notification WhatsApp préparée. ";
                    $message .= "<a href='{$whatsappResult['whatsapp_url']}' target='_blank' class='btn btn-sm btn-success ms-2'>";
                    $message .= "<i class='fab fa-whatsapp'></i> Envoyer WhatsApp</a>";
                } else {
                    $message = "Statut de la commande #{$id} mis à jour avec succès.";
                    if (!$whatsappResult['success']) {
                        $message .= " (Notification WhatsApp non disponible: " . htmlspecialchars($whatsappResult['message']) . ")";
                    }
                }
            } else {
                $error = "Erreur lors de la mise à jour : " . $stmt->error;
            }
            $stmt->close();
        }
    }
}

// Filtres
$filter_status = $_GET['status'] ?? 'all';
$filter_livreur = $_GET['livreur'] ?? 'all';
$search = $_GET['search'] ?? '';

// Construction de la requête
$query = "SELECT c.*, 
                 l.nom as livreur_nom, l.prenom as livreur_prenom, l.telephone as livreur_tel,
                 v.nom as ville_nom
          FROM commandes c
          LEFT JOIN livreurs l ON c.livreur_id = l.id
          LEFT JOIN villes v ON c.ville_id = v.id
          WHERE 1=1";

$params = [];
$types = '';

if ($filter_status !== 'all') {
    $query .= " AND c.status = ?";
    $params[] = $filter_status;
    $types .= 's';
}

if ($filter_livreur !== 'all') {
    if ($filter_livreur === 'none') {
        $query .= " AND c.livreur_id IS NULL";
    } else {
        $query .= " AND c.livreur_id = ?";
        $params[] = (int)$filter_livreur;
        $types .= 'i';
    }
}

if ($search) {
    $query .= " AND (c.name LIKE ? OR c.product_name LIKE ? OR c.transaction_id LIKE ?)";
    $search_param = "%{$search}%";
    $params[] = $search_param;
    $params[] = $search_param;
    $params[] = $search_param;
    $types .= 'sss';
}

$query .= " ORDER BY c.order_date DESC LIMIT 100";

if (!empty($params)) {
    $stmt = $conn->prepare($query);
    $stmt->bind_param($types, ...$params);
    $stmt->execute();
    $result = $stmt->get_result();
} else {
    $result = $conn->query($query);
}

// Récupération des livreurs pour le filtre
$livreurs_result = $conn->query("SELECT id, nom, prenom FROM livreurs WHERE is_active = 1 ORDER BY nom");
?>
<div class="page-header">
    <h1><i class="fas fa-shopping-cart"></i> Gestion des Commandes</h1>
    <p>Gérez toutes les commandes de votre système</p>
</div>

<?php if ($message): ?>
    <div class="alert alert-success"><?php echo htmlspecialchars($message); ?></div>
<?php endif; ?>

<?php if ($error): ?>
    <div class="alert alert-danger"><?php echo htmlspecialchars($error); ?></div>
<?php endif; ?>

<!-- Filtres -->
<div class="content-card">
    <form method="GET" class="row g-3">
        <input type="hidden" name="section" value="commandes">
        <div class="col-md-3">
            <label class="form-label">Statut</label>
            <select name="status" class="form-select">
                <option value="all" <?php echo $filter_status === 'all' ? 'selected' : ''; ?>>Tous</option>
                <option value="en cours" <?php echo $filter_status === 'en cours' ? 'selected' : ''; ?>>En cours</option>
                <option value="PENDING" <?php echo $filter_status === 'PENDING' ? 'selected' : ''; ?>>En attente</option>
                <option value="terminer" <?php echo $filter_status === 'terminer' ? 'selected' : ''; ?>>Terminée</option>
                <option value="CONFIRMED" <?php echo $filter_status === 'CONFIRMED' ? 'selected' : ''; ?>>Confirmée</option>
                <option value="annuler" <?php echo $filter_status === 'annuler' ? 'selected' : ''; ?>>Annulée</option>
            </select>
        </div>
        <div class="col-md-3">
            <label class="form-label">Livreur</label>
            <select name="livreur" class="form-select">
                <option value="all" <?php echo $filter_livreur === 'all' ? 'selected' : ''; ?>>Tous</option>
                <option value="none" <?php echo $filter_livreur === 'none' ? 'selected' : ''; ?>>Sans livreur</option>
                <?php while ($liv = $livreurs_result->fetch_assoc()): ?>
                    <option value="<?php echo $liv['id']; ?>" <?php echo $filter_livreur == $liv['id'] ? 'selected' : ''; ?>>
                        <?php echo htmlspecialchars($liv['nom'] . ' ' . $liv['prenom']); ?>
                    </option>
                <?php endwhile; ?>
            </select>
        </div>
        <div class="col-md-4">
            <label class="form-label">Recherche</label>
            <input type="text" name="search" class="form-control" placeholder="Nom, produit, transaction..." value="<?php echo htmlspecialchars($search); ?>">
        </div>
        <div class="col-md-2">
            <label class="form-label">&nbsp;</label>
            <button type="submit" class="btn btn-primary w-100">
                <i class="fas fa-search"></i> Filtrer
            </button>
        </div>
    </form>
</div>

<!-- Table des commandes -->
<div class="content-card">
    <div class="table-responsive">
        <table class="table table-hover">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Client</th>
                    <th>Produit</th>
                    <th>Quantité</th>
                    <th>Montant</th>
                    <th>Ville</th>
                    <th>Livreur</th>
                    <th>Statut</th>
                    <th>Date</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                <?php
                if ($result && $result->num_rows > 0):
                    while ($row = $result->fetch_assoc()):
                        $status_class = '';
                        $status_text = $row['status'];
                        if (in_array($row['status'], ['terminer', 'TERMINER', 'CONFIRMED'])) {
                            $status_class = 'success';
                            $status_text = 'Terminée';
                        } elseif (in_array($row['status'], ['en cours', 'PENDING', 'EN_COURS'])) {
                            $status_class = 'warning';
                            $status_text = 'En cours';
                        } elseif (in_array($row['status'], ['annuler', 'ANNULER', 'FAILED'])) {
                            $status_class = 'danger';
                            $status_text = 'Annulée';
                        }
                ?>
                <tr>
                    <td><strong>#<?php echo $row['id']; ?></strong></td>
                    <td><?php echo htmlspecialchars($row['name']); ?></td>
                    <td><?php echo htmlspecialchars($row['product_name']); ?></td>
                    <td><?php echo $row['quantity']; ?></td>
                    <td><strong><?php echo number_format($row['total_price'], 2); ?> $</strong></td>
                    <td><?php echo $row['ville_nom'] ? htmlspecialchars($row['ville_nom']) : '<span class="text-muted">-</span>'; ?></td>
                    <td>
                        <?php if ($row['livreur_nom']): ?>
                            <?php echo htmlspecialchars($row['livreur_nom'] . ' ' . $row['livreur_prenom']); ?>
                        <?php else: ?>
                            <span class="badge badge-danger">Non attribué</span>
                        <?php endif; ?>
                    </td>
                    <td><span class="badge badge-<?php echo $status_class; ?>"><?php echo $status_text; ?></span></td>
                    <td><?php echo date('d/m/Y H:i', strtotime($row['order_date'])); ?></td>
                    <td>
                        <div class="btn-group">
                            <button type="button" class="btn btn-sm btn-primary" data-bs-toggle="modal" data-bs-target="#modalCommande<?php echo $row['id']; ?>">
                                <i class="fas fa-eye"></i>
                            </button>
                            <button type="button" class="btn btn-sm btn-warning" data-bs-toggle="modal" data-bs-target="#modalStatus<?php echo $row['id']; ?>">
                                <i class="fas fa-edit"></i>
                            </button>
                            <?php if (!$row['livreur_id']): ?>
                                <a href="?section=attribution&commande_id=<?php echo $row['id']; ?>" class="btn btn-sm btn-info">
                                    <i class="fas fa-user-tie"></i>
                                </a>
                            <?php endif; ?>
                        </div>
                    </td>
                </tr>

                <!-- Modal Détails -->
                <div class="modal fade" id="modalCommande<?php echo $row['id']; ?>" tabindex="-1">
                    <div class="modal-dialog modal-lg">
                        <div class="modal-content">
                            <div class="modal-header">
                                <h5 class="modal-title">Commande #<?php echo $row['id']; ?></h5>
                                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                            </div>
                            <div class="modal-body">
                                <!-- 💡 NOUVEAU : Section prix mise en évidence -->
                                <div class="alert alert-primary mb-4" role="alert">
                                    <div class="d-flex justify-content-between align-items-center">
                                        <div>
                                            <h5 class="mb-1"><i class="fas fa-dollar-sign"></i> Montant total de la commande</h5>
                                            <p class="mb-0 text-muted">Transaction: <?php echo htmlspecialchars($row['transaction_id']); ?></p>
                                        </div>
                                        <div class="text-end">
                                            <h3 class="mb-0 text-primary fw-bold">
                                                <?php echo number_format($row['total_price'], 2); ?> $
                                            </h3>
                                            <?php if ($row['quantity'] > 0): ?>
                                                <small class="text-muted">
                                                    (<?php echo number_format($row['total_price'] / $row['quantity'], 2); ?> $ × <?php echo $row['quantity']; ?>)
                                                </small>
                                            <?php endif; ?>
                                        </div>
                                    </div>
                                </div>
                                
                                <div class="row">
                                    <div class="col-md-6">
                                        <h6><i class="fas fa-user"></i> Informations client</h6>
                                        <hr class="my-2">
                                        <p><strong>Nom:</strong> <?php echo htmlspecialchars($row['name']); ?></p>
                                        <p><strong>Adresse:</strong> <?php echo htmlspecialchars($row['address']); ?></p>
                                        <p><strong>Ville:</strong> <?php echo $row['ville_nom'] ? htmlspecialchars($row['ville_nom']) : '<span class="text-muted">Non spécifiée</span>'; ?></p>
                                        
                                        <!-- 💡 NOUVEAU : Extraire et afficher le téléphone du client -->
                                        <?php
                                        $clientPhone = null;
                                        if (strpos($row['payment_method'], ':') !== false) {
                                            $parts = explode(':', $row['payment_method']);
                                            if (count($parts) >= 2) {
                                                $clientPhone = preg_replace('/[^0-9]/', '', trim($parts[1]));
                                            }
                                        } elseif (preg_match('/^[0-9]{9,15}$/', preg_replace('/[^0-9]/', '', $row['payment_method']))) {
                                            $clientPhone = preg_replace('/[^0-9]/', '', $row['payment_method']);
                                        }
                                        ?>
                                        <?php if ($clientPhone): ?>
                                            <p>
                                                <strong>Téléphone:</strong> 
                                                <a href="https://api.whatsapp.com/send?phone=<?php echo $clientPhone; ?>" 
                                                   target="_blank" 
                                                   class="text-decoration-none">
                                                    <?php echo $clientPhone; ?>
                                                    <i class="fab fa-whatsapp text-success ms-1"></i>
                                                </a>
                                            </p>
                                        <?php endif; ?>
                                    </div>
                                    <div class="col-md-6">
                                        <h6><i class="fas fa-shopping-bag"></i> Informations commande</h6>
                                        <hr class="my-2">
                                        <p><strong>Produit:</strong> <?php echo htmlspecialchars($row['product_name']); ?></p>
                                        <p><strong>Quantité:</strong> <span class="badge bg-info"><?php echo $row['quantity']; ?></span></p>
                                        
                                        <!-- 💡 NOUVEAU : Prix détaillé -->
                                        <div class="card bg-light mb-2">
                                            <div class="card-body p-2">
                                                <div class="d-flex justify-content-between">
                                                    <span><strong>Prix unitaire:</strong></span>
                                                    <span class="fw-bold">
                                                        <?php 
                                                        $prix_unitaire = $row['quantity'] > 0 ? ($row['total_price'] / $row['quantity']) : $row['total_price'];
                                                        echo number_format($prix_unitaire, 2); 
                                                        ?> $
                                                    </span>
                                                </div>
                                                <div class="d-flex justify-content-between mt-1">
                                                    <span><strong>Total:</strong></span>
                                                    <span class="fw-bold text-primary fs-5">
                                                        <?php echo number_format($row['total_price'], 2); ?> $
                                                    </span>
                                                </div>
                                            </div>
                                        </div>
                                        
                                        <p><strong>Paiement:</strong> 
                                            <span class="badge bg-secondary"><?php echo htmlspecialchars($row['payment_method']); ?></span>
                                        </p>
                                        <p><strong>Statut:</strong> 
                                            <span class="badge badge-<?php echo $status_class; ?>"><?php echo $status_text; ?></span>
                                        </p>
                                        <p><strong>Date:</strong> <?php echo date('d/m/Y H:i', strtotime($row['order_date'])); ?></p>
                                    </div>
                                </div>
                                <?php if ($row['livreur_nom']): ?>
                                <hr>
                                <h6><i class="fas fa-motorcycle"></i> Livreur assigné</h6>
                                <div class="row">
                                    <div class="col-md-6">
                                        <p><strong>Nom:</strong> <?php echo htmlspecialchars($row['livreur_nom'] . ' ' . $row['livreur_prenom']); ?></p>
                                    </div>
                                    <div class="col-md-6">
                                        <p><strong>Téléphone:</strong> 
                                            <?php if ($row['livreur_tel']): ?>
                                                <a href="https://api.whatsapp.com/send?phone=<?php echo preg_replace('/[^0-9]/', '', $row['livreur_tel']); ?>" 
                                                   target="_blank" 
                                                   class="text-decoration-none">
                                                    <?php echo htmlspecialchars($row['livreur_tel']); ?>
                                                    <i class="fab fa-whatsapp text-success ms-1"></i>
                                                </a>
                                            <?php else: ?>
                                                <span class="text-muted">Non disponible</span>
                                            <?php endif; ?>
                                        </p>
                                    </div>
                                </div>
                                <?php endif; ?>
                                
                                <?php if ($row['latitude'] && $row['longitude']): ?>
                                <hr>
                                <h6><i class="fas fa-map-marker-alt"></i> Localisation</h6>
                                <p><strong>Coordonnées GPS:</strong> 
                                    <code><?php echo number_format($row['latitude'], 6); ?>, <?php echo number_format($row['longitude'], 6); ?></code>
                                </p>
                                <a href="https://maps.google.com/?q=<?php echo $row['latitude']; ?>,<?php echo $row['longitude']; ?>" 
                                   target="_blank" 
                                   class="btn btn-sm btn-primary">
                                    <i class="fas fa-map-marked-alt"></i> Voir sur Google Maps
                                </a>
                                <?php endif; ?>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Modal Statut -->
                <div class="modal fade" id="modalStatus<?php echo $row['id']; ?>" tabindex="-1">
                    <div class="modal-dialog">
                        <div class="modal-content">
                            <form method="POST">
                                <input type="hidden" name="csrf_token" value="<?php echo $_SESSION['csrf_token']; ?>">
                                <input type="hidden" name="update_status" value="1">
                                <input type="hidden" name="id" value="<?php echo $row['id']; ?>">
                                <div class="modal-header">
                                    <h5 class="modal-title">Modifier le statut - Commande #<?php echo $row['id']; ?></h5>
                                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                                </div>
                                <div class="modal-body">
                                    <div class="mb-3">
                                        <label class="form-label">Nouveau statut</label>
                                        <select name="new_status" class="form-select" required>
                                            <option value="en cours" <?php echo $row['status'] === 'en cours' ? 'selected' : ''; ?>>En cours</option>
                                            <option value="PENDING" <?php echo $row['status'] === 'PENDING' ? 'selected' : ''; ?>>En attente</option>
                                            <option value="terminer" <?php echo $row['status'] === 'terminer' ? 'selected' : ''; ?>>Terminée</option>
                                            <option value="CONFIRMED" <?php echo $row['status'] === 'CONFIRMED' ? 'selected' : ''; ?>>Confirmée</option>
                                            <option value="annuler" <?php echo $row['status'] === 'annuler' ? 'selected' : ''; ?>>Annulée</option>
                                        </select>
                                    </div>
                                </div>
                                <div class="modal-footer">
                                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Annuler</button>
                                    <button type="submit" class="btn btn-primary">Enregistrer</button>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>
                <?php
                    endwhile;
                else:
                ?>
                <tr>
                    <td colspan="10" class="text-center text-muted">Aucune commande trouvée</td>
                </tr>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
</div>

