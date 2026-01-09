<?php
// attribution.php - Attribution des livreurs aux commandes

// Fonction pour construire l'URL du backend
if (!function_exists('getBackendURL')) {
    function getBackendURL($file) {
        // Utiliser __DIR__ pour obtenir le chemin réel du fichier inclus
        $backend_dir = dirname(__DIR__);
        $doc_root = $_SERVER['DOCUMENT_ROOT'];
        
        // Normaliser les chemins (supprimer les slashes finaux)
        $backend_dir = rtrim($backend_dir, '/\\');
        $doc_root = rtrim($doc_root, '/\\');
        
        // Obtenir le chemin relatif depuis la racine du document
        $relative_path = str_replace($doc_root, '', $backend_dir);
        $relative_path = str_replace('\\', '/', $relative_path); // Normaliser les slashes
        
        // Construire l'URL complète
        $protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
        $host = $_SERVER['HTTP_HOST'];
        
        return $protocol . '://' . $host . $relative_path . '/' . $file;
    }
}

// Fonction utilitaire pour les requêtes cURL vers les APIs internes
if (!function_exists('callInternalAPI')) {
    function callInternalAPI($url, $data = [], $method = 'POST') {
        $ch = curl_init($url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_POST, ($method === 'POST'));
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $method);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'Accept: application/json'
        ]);
        curl_setopt($ch, CURLOPT_TIMEOUT, 30);
        curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 10);
        
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $curlError = curl_error($ch);
        $curlErrno = curl_errno($ch);
        curl_close($ch);
        
        if ($curlErrno !== 0 || $response === false) {
            error_log("Erreur cURL pour $url: [$curlErrno] $curlError");
            return [
                'success' => false,
                'data' => null,
                'error' => "Erreur de connexion: " . ($curlError ?: "Erreur inconnue (code: $curlErrno)"),
                'http_code' => 0
            ];
        }
        
        if ($httpCode < 200 || $httpCode >= 300) {
            error_log("Code HTTP d'erreur pour $url: $httpCode - Réponse: " . substr($response, 0, 500));
            $errorMessage = "Erreur serveur (code HTTP: $httpCode)";
            $decoded = json_decode($response, true);
            if ($decoded && isset($decoded['message'])) {
                $errorMessage = $decoded['message'];
            } elseif (!empty($response)) {
                $errorMessage .= " - " . substr($response, 0, 200);
            }
            return [
                'success' => false,
                'data' => null,
                'error' => $errorMessage,
                'http_code' => $httpCode
            ];
        }
        
        $decoded = json_decode($response, true);
        if (json_last_error() !== JSON_ERROR_NONE) {
            error_log("Erreur de décodage JSON pour $url: " . json_last_error_msg() . " - Réponse: " . substr($response, 0, 500));
            return [
                'success' => false,
                'data' => null,
                'error' => "Réponse invalide du serveur: " . json_last_error_msg(),
                'http_code' => $httpCode
            ];
        }
        
        $success = isset($decoded['success']) ? $decoded['success'] : ($httpCode >= 200 && $httpCode < 300);
        return [
            'success' => $success,
            'data' => $decoded,
            'error' => $success ? null : ($decoded['message'] ?? 'Erreur inconnue'),
            'http_code' => $httpCode
        ];
    }
}

// Traitement de l'attribution
if ($_SERVER['REQUEST_METHOD'] === 'POST' && (isset($_POST['attribuer']) || isset($_POST['modifier_livreur']))) {
    if (!isset($_POST['csrf_token']) || $_POST['csrf_token'] !== $_SESSION['csrf_token']) {
        $error = "Erreur de sécurité : Jeton CSRF invalide.";
    } else {
        $commande_id = filter_input(INPUT_POST, 'commande_id', FILTER_VALIDATE_INT);
        $livreur_id = filter_input(INPUT_POST, 'livreur_id', FILTER_VALIDATE_INT);
        
        if ($commande_id && $livreur_id) {
            // Appel à l'API d'attribution (fonctionne pour attribution et modification)
            $data = [
                'commande_id' => $commande_id,
                'livreur_id' => $livreur_id
            ];
            
            // Construire l'URL du backend
            $url = getBackendURL('attribuer_livreur.php');
            $result = callInternalAPI($url, $data, 'POST');
            
            if ($result['success'] && $result['data'] && isset($result['data']['success']) && $result['data']['success']) {
                if (isset($_POST['modifier_livreur'])) {
                    $message = $result['data']['message'] ?? "Livreur modifié avec succès pour la commande #{$commande_id}.";
                } else {
                    $message = $result['data']['message'] ?? "Livreur attribué avec succès à la commande #{$commande_id}.";
                }
            } else {
                $error = $result['error'] ?? ($result['data']['message'] ?? "Erreur lors de l'attribution.");
                error_log("Erreur attribution livreur: " . $error);
            }
        }
    }
}

// Récupération des commandes sans livreur
$query = "SELECT c.*, v.nom as ville_nom
          FROM commandes c
          LEFT JOIN villes v ON c.ville_id = v.id
          WHERE c.livreur_id IS NULL 
          AND c.status IN ('en cours', 'PENDING', 'EN_COURS')
          ORDER BY c.order_date DESC";
$commandes_sans_livreur = $conn->query($query);

// Récupération de toutes les commandes avec livreur
$query_all = "SELECT c.*, 
                     l.nom as livreur_nom, l.prenom as livreur_prenom, l.id as livreur_id,
                     v.nom as ville_nom, v.id as ville_id
              FROM commandes c
              LEFT JOIN livreurs l ON c.livreur_id = l.id
              LEFT JOIN villes v ON c.ville_id = v.id
              ORDER BY c.order_date DESC
              LIMIT 50";
$toutes_commandes = $conn->query($query_all);
?>
<div class="page-header">
    <h1><i class="fas fa-user-tie"></i> Attribution des Livreurs</h1>
    <p>Gérez l'attribution des livreurs aux commandes</p>
</div>

<?php if ($message): ?>
    <div class="alert alert-success"><?php echo htmlspecialchars($message); ?></div>
<?php endif; ?>

<?php if ($error): ?>
    <div class="alert alert-danger"><?php echo htmlspecialchars($error); ?></div>
<?php endif; ?>

<!-- Commandes sans livreur -->
<div class="content-card">
    <h2><i class="fas fa-exclamation-triangle text-danger"></i> Commandes sans livreur (<?php echo $commandes_sans_livreur->num_rows; ?>)</h2>
    <div class="table-responsive">
        <table class="table table-hover">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Client</th>
                    <th>Produit</th>
                    <th>Ville</th>
                    <th>Adresse</th>
                    <th>Montant</th>
                    <th>Date</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                <?php
                if ($commandes_sans_livreur && $commandes_sans_livreur->num_rows > 0):
                    while ($row = $commandes_sans_livreur->fetch_assoc()):
                        // Récupérer les livreurs disponibles pour cette ville
                        $livreurs_query = "SELECT l.id, l.nom, l.prenom, l.telephone, l.nombre_commandes_actuelles, vl.is_primary
                                          FROM livreurs l
                                          INNER JOIN ville_livreur vl ON l.id = vl.livreur_id
                                          WHERE vl.ville_id = ? AND l.is_active = 1 AND l.is_available = 1
                                          ORDER BY vl.is_primary DESC, l.nombre_commandes_actuelles ASC";
                        $stmt_liv = $conn->prepare($livreurs_query);
                        $stmt_liv->bind_param("i", $row['ville_id']);
                        $stmt_liv->execute();
                        $livreurs = $stmt_liv->get_result();
                ?>
                <tr>
                    <td><strong>#<?php echo $row['id']; ?></strong></td>
                    <td><?php echo htmlspecialchars($row['name']); ?></td>
                    <td><?php echo htmlspecialchars($row['product_name']); ?></td>
                    <td><?php echo $row['ville_nom'] ? htmlspecialchars($row['ville_nom']) : '<span class="text-muted">Non spécifiée</span>'; ?></td>
                    <td><?php echo htmlspecialchars(substr($row['address'], 0, 50)); ?>...</td>
                    <td><strong><?php echo number_format($row['total_price'], 2); ?> $</strong></td>
                    <td><?php echo date('d/m/Y H:i', strtotime($row['order_date'])); ?></td>
                    <td>
                        <?php if ($livreurs->num_rows > 0): ?>
                            <button type="button" class="btn btn-sm btn-primary" data-bs-toggle="modal" data-bs-target="#modalAttribuer<?php echo $row['id']; ?>">
                                <i class="fas fa-user-tie"></i> Attribuer
                            </button>
                        <?php else: ?>
                            <span class="badge badge-warning">Aucun livreur disponible</span>
                        <?php endif; ?>
                    </td>
                </tr>

                <!-- Modal Attribution -->
                <div class="modal fade" id="modalAttribuer<?php echo $row['id']; ?>" tabindex="-1">
                    <div class="modal-dialog">
                        <div class="modal-content">
                            <form method="POST">
                                <input type="hidden" name="csrf_token" value="<?php echo $_SESSION['csrf_token']; ?>">
                                <input type="hidden" name="attribuer" value="1">
                                <input type="hidden" name="commande_id" value="<?php echo $row['id']; ?>">
                                <div class="modal-header">
                                    <h5 class="modal-title">Attribuer un livreur - Commande #<?php echo $row['id']; ?></h5>
                                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                                </div>
                                <div class="modal-body">
                                    <p><strong>Client:</strong> <?php echo htmlspecialchars($row['name']); ?></p>
                                    <p><strong>Ville:</strong> <?php echo $row['ville_nom'] ? htmlspecialchars($row['ville_nom']) : 'Non spécifiée'; ?></p>
                                    <div class="mb-3">
                                        <label class="form-label">Sélectionner un livreur</label>
                                        <select name="livreur_id" class="form-select" required>
                                            <option value="">-- Choisir un livreur --</option>
                                            <?php while ($liv = $livreurs->fetch_assoc()): ?>
                                                <option value="<?php echo $liv['id']; ?>" <?php echo $liv['is_primary'] ? 'selected' : ''; ?>>
                                                    <?php echo htmlspecialchars($liv['nom'] . ' ' . $liv['prenom']); ?>
                                                    (<?php echo $liv['nombre_commandes_actuelles']; ?> commandes)
                                                    <?php echo $liv['is_primary'] ? ' - Principal' : ''; ?>
                                                </option>
                                            <?php endwhile; ?>
                                        </select>
                                    </div>
                                </div>
                                <div class="modal-footer">
                                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Annuler</button>
                                    <button type="submit" class="btn btn-primary">Attribuer</button>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>
                <?php
                        $stmt_liv->close();
                    endwhile;
                else:
                ?>
                <tr>
                    <td colspan="8" class="text-center text-success">
                        <i class="fas fa-check-circle"></i> Toutes les commandes ont un livreur attribué !
                    </td>
                </tr>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
</div>

<!-- Toutes les commandes avec livreur -->
<div class="content-card">
    <h2><i class="fas fa-list"></i> Toutes les commandes</h2>
    <div class="table-responsive">
        <table class="table table-hover">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Client</th>
                    <th>Produit</th>
                    <th>Ville</th>
                    <th>Livreur</th>
                    <th>Statut</th>
                    <th>Date attribution</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                <?php
                if ($toutes_commandes && $toutes_commandes->num_rows > 0):
                    while ($row = $toutes_commandes->fetch_assoc()):
                ?>
                <tr>
                    <td><strong>#<?php echo $row['id']; ?></strong></td>
                    <td><?php echo htmlspecialchars($row['name']); ?></td>
                    <td><?php echo htmlspecialchars($row['product_name']); ?></td>
                    <td><?php echo $row['ville_nom'] ? htmlspecialchars($row['ville_nom']) : '-'; ?></td>
                    <td>
                        <?php if ($row['livreur_nom']): ?>
                            <?php echo htmlspecialchars($row['livreur_nom'] . ' ' . $row['livreur_prenom']); ?>
                        <?php else: ?>
                            <span class="badge badge-danger">Non attribué</span>
                        <?php endif; ?>
                    </td>
                    <td><span class="badge badge-<?php echo in_array($row['status'], ['terminer', 'TERMINER', 'CONFIRMED']) ? 'success' : 'warning'; ?>">
                        <?php echo htmlspecialchars($row['status']); ?>
                    </span></td>
                    <td><?php echo $row['attribution_date'] ? date('d/m/Y H:i', strtotime($row['attribution_date'])) : '-'; ?></td>
                    <td>
                        <button type="button" class="btn btn-sm <?php echo $row['livreur_id'] ? 'btn-warning' : 'btn-primary'; ?>" data-bs-toggle="modal" data-bs-target="#modalModifierLivreur<?php echo $row['id']; ?>">
                            <i class="fas fa-<?php echo $row['livreur_id'] ? 'exchange-alt' : 'user-tie'; ?>"></i> 
                            <?php echo $row['livreur_id'] ? 'Modifier' : 'Attribuer'; ?>
                        </button>
                    </td>
                </tr>

                <!-- Modal Attribution/Modification Livreur -->
                <?php
                // Récupérer les livreurs disponibles pour cette ville
                $livreurs_modif_query = "SELECT l.id, l.nom, l.prenom, l.telephone, l.nombre_commandes_actuelles, vl.is_primary
                                      FROM livreurs l
                                      INNER JOIN ville_livreur vl ON l.id = vl.livreur_id
                                      WHERE vl.ville_id = ? AND l.is_active = 1 AND l.is_available = 1
                                      ORDER BY vl.is_primary DESC, l.nombre_commandes_actuelles ASC";
                $stmt_modif = $conn->prepare($livreurs_modif_query);
                if ($row['ville_id']) {
                    $stmt_modif->bind_param("i", $row['ville_id']);
                    $stmt_modif->execute();
                    $livreurs_modif = $stmt_modif->get_result();
                } else {
                    // Si pas de ville, récupérer tous les livreurs disponibles
                    $livreurs_modif_query_all = "SELECT l.id, l.nom, l.prenom, l.telephone, l.nombre_commandes_actuelles
                                               FROM livreurs l
                                               WHERE l.is_active = 1 AND l.is_available = 1
                                               ORDER BY l.nombre_commandes_actuelles ASC";
                    $livreurs_modif = $conn->query($livreurs_modif_query_all);
                    $stmt_modif = null;
                }
                ?>
                <div class="modal fade" id="modalModifierLivreur<?php echo $row['id']; ?>" tabindex="-1">
                    <div class="modal-dialog">
                        <div class="modal-content">
                            <form method="POST">
                                <input type="hidden" name="csrf_token" value="<?php echo $_SESSION['csrf_token']; ?>">
                                <input type="hidden" name="modifier_livreur" value="1">
                                <input type="hidden" name="commande_id" value="<?php echo $row['id']; ?>">
                                <div class="modal-header">
                                    <h5 class="modal-title">
                                        <?php echo $row['livreur_id'] ? 'Modifier le livreur' : 'Attribuer un livreur'; ?> - Commande #<?php echo $row['id']; ?>
                                    </h5>
                                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                                </div>
                                <div class="modal-body">
                                    <p><strong>Client:</strong> <?php echo htmlspecialchars($row['name']); ?></p>
                                    <p><strong>Ville:</strong> <?php echo $row['ville_nom'] ? htmlspecialchars($row['ville_nom']) : 'Non spécifiée'; ?></p>
                                    <?php if ($row['livreur_id']): ?>
                                        <p><strong>Livreur actuel:</strong> 
                                            <span class="badge badge-info">
                                                <?php echo htmlspecialchars($row['livreur_nom'] . ' ' . $row['livreur_prenom']); ?>
                                            </span>
                                        </p>
                                    <?php else: ?>
                                        <p><strong>Livreur actuel:</strong> 
                                            <span class="badge badge-danger">Non attribué</span>
                                        </p>
                                    <?php endif; ?>
                                    <div class="mb-3">
                                        <label class="form-label"><?php echo $row['livreur_id'] ? 'Sélectionner un nouveau livreur' : 'Sélectionner un livreur'; ?></label>
                                        <select name="livreur_id" class="form-select" required>
                                            <option value="">-- Choisir un livreur --</option>
                                            <?php 
                                            if ($livreurs_modif && $livreurs_modif->num_rows > 0):
                                                while ($liv_modif = $livreurs_modif->fetch_assoc()): 
                                                    $selected = ($liv_modif['id'] == $row['livreur_id']) ? 'selected' : '';
                                                    // Si pas de livreur actuel, sélectionner le principal par défaut
                                                    if (!$row['livreur_id'] && isset($liv_modif['is_primary']) && $liv_modif['is_primary']) {
                                                        $selected = 'selected';
                                                    }
                                            ?>
                                                <option value="<?php echo $liv_modif['id']; ?>" <?php echo $selected; ?>>
                                                    <?php echo htmlspecialchars($liv_modif['nom'] . ' ' . $liv_modif['prenom']); ?>
                                                    (<?php echo $liv_modif['nombre_commandes_actuelles']; ?> commandes)
                                                    <?php echo isset($liv_modif['is_primary']) && $liv_modif['is_primary'] ? ' - Principal' : ''; ?>
                                                </option>
                                            <?php 
                                                endwhile;
                                            else:
                                            ?>
                                                <option value="" disabled>Aucun livreur disponible pour cette ville</option>
                                            <?php
                                            endif;
                                            ?>
                                        </select>
                                    </div>
                                </div>
                                <div class="modal-footer">
                                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Annuler</button>
                                    <button type="submit" class="btn <?php echo $row['livreur_id'] ? 'btn-warning' : 'btn-primary'; ?>">
                                        <i class="fas fa-<?php echo $row['livreur_id'] ? 'exchange-alt' : 'user-tie'; ?>"></i> 
                                        <?php echo $row['livreur_id'] ? 'Modifier' : 'Attribuer'; ?>
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>
                <?php
                if ($stmt_modif) {
                    $stmt_modif->close();
                }
                ?>
                <?php
                    endwhile;
                endif;
                ?>
            </tbody>
        </table>
    </div>
</div>

