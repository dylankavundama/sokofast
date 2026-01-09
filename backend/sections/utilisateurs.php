<?php
// utilisateurs.php - Gestion des utilisateurs

// Traitement des actions POST
if ($_SERVER['REQUEST_METHOD'] === 'POST' && (!isset($processing_post_only) || $processing_post_only)) {
    if (!isset($_POST['csrf_token']) || $_POST['csrf_token'] !== $_SESSION['csrf_token']) {
        $error = "Erreur de sécurité : Jeton CSRF invalide.";
    } else {
        if (isset($_POST['update_status'])) {
            // Mettre à jour le statut d'un utilisateur
            $firebase_uid = trim($_POST['firebase_uid'] ?? '');
            $statut = isset($_POST['statut']) && in_array($_POST['statut'], ['client', 'vendeur']) ? $_POST['statut'] : null;
            
            if (empty($firebase_uid) || $statut === null) {
                $error = "Données invalides pour la mise à jour du statut.";
            } else {
                // Mise à jour directe dans la base de données
                $update_query = "UPDATE utilisateurs SET statut = ?, updated_at = NOW() WHERE firebase_uid = ?";
                $update_stmt = $conn->prepare($update_query);
                
                if ($update_stmt) {
                    $update_stmt->bind_param("ss", $statut, $firebase_uid);
                    if ($update_stmt->execute()) {
                        if ($update_stmt->affected_rows > 0) {
                            $message = "Statut mis à jour avec succès. L'utilisateur est maintenant " . ($statut === 'vendeur' ? 'vendeur' : 'client') . ".";
                            header("Location: systeme_gestion.php?section=utilisateurs&message=" . urlencode($message));
                            exit();
                        } else {
                            $error = "Utilisateur non trouvé ou aucune modification nécessaire.";
                        }
                    } else {
                        $error = "Erreur lors de la mise à jour : " . $update_stmt->error;
                    }
                    $update_stmt->close();
                } else {
                    $error = "Erreur de préparation de la requête : " . $conn->error;
                }
            }
        }
    }
}

// 💡 Si on est en mode traitement POST uniquement, on s'arrête ici
if (isset($processing_post_only) && $processing_post_only) {
    return; // Sortir sans afficher le HTML
}

// Récupération des messages
if (isset($_GET['message'])) {
    $message = htmlspecialchars($_GET['message']);
}

// Filtres
$filter_statut = $_GET['statut'] ?? 'all';
$search = $_GET['search'] ?? '';

// Construction de la requête
$query = "SELECT id, firebase_uid, email, nom, photo_url, statut, is_active, created_at, updated_at 
          FROM utilisateurs 
          WHERE 1=1";

$params = [];
$types = '';

if ($filter_statut !== 'all') {
    $query .= " AND statut = ?";
    $params[] = $filter_statut;
    $types .= 's';
}

if (!empty($search)) {
    $query .= " AND (email LIKE ? OR nom LIKE ? OR firebase_uid LIKE ?)";
    $search_param = "%$search%";
    $params[] = $search_param;
    $params[] = $search_param;
    $params[] = $search_param;
    $types .= 'sss';
}

$query .= " ORDER BY created_at DESC LIMIT 100";

$stmt = $conn->prepare($query);
if (!empty($params)) {
    $stmt->bind_param($types, ...$params);
}
$stmt->execute();
$result = $stmt->get_result();
?>
<div class="page-header">
    <div class="d-flex justify-content-between align-items-center">
        <div>
            <h1><i class="fas fa-users"></i> Gestion des Utilisateurs</h1>
            <p>Gérez les utilisateurs et leurs statuts (client/vendeur)</p>
        </div>
    </div>
</div>

<?php if (isset($message) && $message): ?>
    <div class="alert alert-success alert-dismissible fade show">
        <?php echo htmlspecialchars($message); ?>
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
<?php endif; ?>

<?php if (isset($error) && $error): ?>
    <div class="alert alert-danger alert-dismissible fade show">
        <?php echo htmlspecialchars($error); ?>
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
<?php endif; ?>

<!-- Filtres et recherche -->
<div class="content-card mb-3">
    <form method="GET" action="systeme_gestion.php" class="row g-3">
        <input type="hidden" name="section" value="utilisateurs">
        <div class="col-md-4">
            <label class="form-label">Statut</label>
            <select name="statut" class="form-select">
                <option value="all" <?php echo $filter_statut === 'all' ? 'selected' : ''; ?>>Tous</option>
                <option value="client" <?php echo $filter_statut === 'client' ? 'selected' : ''; ?>>Clients</option>
                <option value="vendeur" <?php echo $filter_statut === 'vendeur' ? 'selected' : ''; ?>>Vendeurs</option>
            </select>
        </div>
        <div class="col-md-6">
            <label class="form-label">Recherche</label>
            <input type="text" name="search" class="form-control" placeholder="Email, nom ou Firebase UID..." value="<?php echo htmlspecialchars($search); ?>">
        </div>
        <div class="col-md-2">
            <label class="form-label">&nbsp;</label>
            <button type="submit" class="btn btn-primary w-100">
                <i class="fas fa-search"></i> Filtrer
            </button>
        </div>
    </form>
</div>

<div class="content-card">
    <div class="table-responsive">
        <table class="table table-hover">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Email</th>
                    <th>Nom</th>
                    <th>Firebase UID</th>
                    <th>Statut</th>
                    <th>Compte actif</th>
                    <th>Date d'inscription</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                <?php
                if ($result && $result->num_rows > 0):
                    while ($row = $result->fetch_assoc()):
                ?>
                <tr>
                    <td><strong>#<?php echo $row['id']; ?></strong></td>
                    <td><?php echo htmlspecialchars($row['email']); ?></td>
                    <td><?php echo htmlspecialchars($row['nom'] ?? '-'); ?></td>
                    <td>
                        <code style="font-size: 0.75em; background: #f0f0f0; padding: 2px 6px; border-radius: 4px;">
                            <?php echo htmlspecialchars(substr($row['firebase_uid'], 0, 25)) . '...'; ?>
                        </code>
                    </td>
                    <td>
                        <span class="badge badge-<?php echo $row['statut'] === 'vendeur' ? 'warning' : 'info'; ?>">
                            <?php echo $row['statut'] === 'vendeur' ? 'Vendeur' : 'Client'; ?>
                        </span>
                    </td>
                    <td>
                        <?php if ($row['is_active']): ?>
                            <span class="badge badge-success">Actif</span>
                        <?php else: ?>
                            <span class="badge badge-danger">Inactif</span>
                        <?php endif; ?>
                    </td>
                    <td>
                        <small><?php echo date('d/m/Y', strtotime($row['created_at'])); ?></small><br>
                        <small class="text-muted"><?php echo date('H:i', strtotime($row['created_at'])); ?></small>
                    </td>
                    <td>
                        <div class="btn-group">
                            <button type="button" class="btn btn-sm btn-warning" data-bs-toggle="modal" data-bs-target="#modalChangeStatus<?php echo $row['id']; ?>">
                                <i class="fas fa-edit"></i> Modifier statut
                            </button>
                            <?php if ($row['statut'] === 'client'): ?>
                                <button type="button" class="btn btn-sm btn-success" data-bs-toggle="modal" data-bs-target="#modalPromoteVendeur<?php echo $row['id']; ?>" title="Promouvoir en vendeur">
                                    <i class="fas fa-user-tie"></i> Promouvoir vendeur
                                </button>
                            <?php endif; ?>
                        </div>
                    </td>
                </tr>

                <!-- Modal Modifier Statut -->
                <div class="modal fade" id="modalChangeStatus<?php echo $row['id']; ?>" tabindex="-1">
                    <div class="modal-dialog">
                        <div class="modal-content">
                            <form method="POST" action="systeme_gestion.php?section=utilisateurs">
                                <input type="hidden" name="csrf_token" value="<?php echo $_SESSION['csrf_token']; ?>">
                                <input type="hidden" name="update_status" value="1">
                                <input type="hidden" name="firebase_uid" value="<?php echo htmlspecialchars($row['firebase_uid']); ?>">
                                <div class="modal-header">
                                    <h5 class="modal-title">Modifier le statut - <?php echo htmlspecialchars($row['email']); ?></h5>
                                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                                </div>
                                <div class="modal-body">
                                    <div class="mb-3">
                                        <label class="form-label">Statut actuel</label>
                                        <input type="text" class="form-control" value="<?php echo $row['statut'] === 'vendeur' ? 'Vendeur' : 'Client'; ?>" readonly>
                                    </div>
                                    <div class="mb-3">
                                        <label class="form-label">Nouveau statut *</label>
                                        <select name="statut" class="form-select" required>
                                            <option value="client" <?php echo $row['statut'] === 'client' ? 'selected' : ''; ?>>Client</option>
                                            <option value="vendeur" <?php echo $row['statut'] === 'vendeur' ? 'selected' : ''; ?>>Vendeur</option>
                                        </select>
                                    </div>
                                    <div class="alert alert-info">
                                        <i class="fas fa-info-circle"></i>
                                        <strong>Note :</strong> Les vendeurs peuvent ajouter des produits dans l'application mobile.
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

                <!-- Modal Promouvoir en Vendeur (Rapide) -->
                <?php if ($row['statut'] === 'client'): ?>
                <div class="modal fade" id="modalPromoteVendeur<?php echo $row['id']; ?>" tabindex="-1">
                    <div class="modal-dialog">
                        <div class="modal-content">
                            <form method="POST" action="systeme_gestion.php?section=utilisateurs">
                                <input type="hidden" name="csrf_token" value="<?php echo $_SESSION['csrf_token']; ?>">
                                <input type="hidden" name="update_status" value="1">
                                <input type="hidden" name="firebase_uid" value="<?php echo htmlspecialchars($row['firebase_uid']); ?>">
                                <input type="hidden" name="statut" value="vendeur">
                                <div class="modal-header bg-warning">
                                    <h5 class="modal-title">
                                        <i class="fas fa-user-tie"></i> Promouvoir en Vendeur
                                    </h5>
                                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                                </div>
                                <div class="modal-body">
                                    <p><strong>Utilisateur :</strong> <?php echo htmlspecialchars($row['email']); ?></p>
                                    <p><strong>Nom :</strong> <?php echo htmlspecialchars($row['nom'] ?? 'Non renseigné'); ?></p>
                                    <div class="alert alert-warning">
                                        <i class="fas fa-exclamation-triangle"></i>
                                        <strong>Attention :</strong> Cette action permettra à cet utilisateur d'ajouter des produits dans l'application mobile.
                                    </div>
                                    <p>Êtes-vous sûr de vouloir promouvoir cet utilisateur en vendeur ?</p>
                                </div>
                                <div class="modal-footer">
                                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Annuler</button>
                                    <button type="submit" class="btn btn-warning">
                                        <i class="fas fa-check"></i> Oui, promouvoir en vendeur
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>
                <?php endif; ?>
                <?php
                    endwhile;
                else:
                ?>
                <tr>
                    <td colspan="8" class="text-center text-muted">Aucun utilisateur trouvé</td>
                </tr>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
</div>

<?php
if (isset($stmt)) {
    $stmt->close();
}
?>

