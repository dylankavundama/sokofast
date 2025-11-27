<?php
// livreurs.php - Gestion des livreurs

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

// Traitement des actions POST
// 💡 Si $processing_post_only est défini, on traite uniquement le POST sans afficher le HTML
if ($_SERVER['REQUEST_METHOD'] === 'POST' && (!isset($processing_post_only) || $processing_post_only)) {
    if (!isset($_POST['csrf_token']) || $_POST['csrf_token'] !== $_SESSION['csrf_token']) {
        $error = "Erreur de sécurité : Jeton CSRF invalide.";
    } else {
        if (isset($_POST['toggle_availability'])) {
            $livreur_id = filter_input(INPUT_POST, 'livreur_id', FILTER_VALIDATE_INT);
            $is_available = filter_input(INPUT_POST, 'is_available', FILTER_VALIDATE_INT);
            
            if ($livreur_id !== false) {
                $stmt = $conn->prepare("UPDATE livreurs SET is_available = ? WHERE id = ?");
                $stmt->bind_param("ii", $is_available, $livreur_id);
                if ($stmt->execute()) {
                    $message = "Disponibilité du livreur mise à jour.";
                }
                $stmt->close();
            }
        } elseif (isset($_POST['save_livreur'])) {
            // Sauvegarder un livreur (ajout ou modification)
            $data = [
                'nom' => $_POST['nom'],
                'prenom' => $_POST['prenom'],
                'telephone' => $_POST['telephone'],
                'email' => $_POST['email'] ?? '',
                'is_active' => isset($_POST['is_active']) ? 1 : 0,
                'is_available' => isset($_POST['is_available']) ? 1 : 0
            ];
            
            if (isset($_POST['livreur_id']) && !empty($_POST['livreur_id'])) {
                $data['id'] = (int)$_POST['livreur_id'];
            }
            
            // Construire l'URL du backend
            $url = getBackendURL('add_livreur.php');
            $result = callInternalAPI($url, $data, 'POST');
            
            if ($result['success'] && $result['data'] && isset($result['data']['message'])) {
                $message = $result['data']['message'];
                header("Location: systeme_gestion.php?section=livreurs&message=" . urlencode($message));
                exit();
            } else {
                $error = $result['error'] ?? ($result['data']['message'] ?? 'Erreur lors de la sauvegarde');
                error_log("Erreur sauvegarde livreur: " . $error);
            }
        } elseif (isset($_POST['assign_ville_livreur'])) {
            // Assigner une ville à un livreur
            $data = [
                'ville_id' => (int)$_POST['ville_id'],
                'livreur_id' => (int)$_POST['livreur_id'],
                'is_primary' => isset($_POST['is_primary']) ? 1 : 0
            ];
            
            // Construire l'URL du backend
            $url = getBackendURL('associer_ville_livreur.php');
            $result = callInternalAPI($url, $data, 'POST');
            
            if ($result['success'] && $result['data'] && isset($result['data']['message'])) {
                $message = $result['data']['message'];
                header("Location: systeme_gestion.php?section=livreurs&message=" . urlencode($message));
                exit();
            } else {
                $error = $result['error'] ?? ($result['data']['message'] ?? 'Erreur lors de l\'assignation');
                error_log("Erreur assignation ville: " . $error);
            }
        } elseif (isset($_POST['remove_ville_livreur'])) {
            // Retirer une ville d'un livreur
            $data = [
                'ville_id' => (int)$_POST['ville_id'],
                'livreur_id' => (int)$_POST['livreur_id'],
                'action' => 'remove'
            ];
            
            // Construire l'URL du backend
            $url = getBackendURL('associer_ville_livreur.php');
            $result = callInternalAPI($url, $data, 'POST');
            
            if ($result['success'] && $result['data'] && isset($result['data']['message'])) {
                $message = $result['data']['message'];
                header("Location: systeme_gestion.php?section=livreurs&message=" . urlencode($message));
                exit();
            } else {
                $error = $result['error'] ?? ($result['data']['message'] ?? 'Erreur lors de la suppression');
                error_log("Erreur suppression ville: " . $error);
            }
        } elseif (isset($_POST['delete_livreur'])) {
            // 💡 NOUVEAU : Supprimer un livreur
            $data = [
                'id' => (int)$_POST['livreur_id'],
                'action' => 'delete'
            ];
            
            // Construire l'URL du backend
            $url = getBackendURL('add_livreur.php');
            $result = callInternalAPI($url, $data, 'POST');
            
            if ($result['success'] && $result['data'] && isset($result['data']['message'])) {
                $message = $result['data']['message'];
                header("Location: systeme_gestion.php?section=livreurs&message=" . urlencode($message));
                exit();
            } else {
                $error = $result['error'] ?? ($result['data']['message'] ?? 'Erreur lors de la suppression du livreur');
                error_log("Erreur suppression livreur: " . $error);
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

// Récupération des livreurs avec statistiques
$query = "SELECT l.*, 
                 COUNT(c.id) as total_commandes,
                 SUM(CASE WHEN c.status IN ('terminer', 'TERMINER', 'CONFIRMED') THEN 1 ELSE 0 END) as commandes_terminees,
                 GROUP_CONCAT(DISTINCT v.nom SEPARATOR ', ') as villes
          FROM livreurs l
          LEFT JOIN commandes c ON l.id = c.livreur_id
          LEFT JOIN ville_livreur vl ON l.id = vl.livreur_id
          LEFT JOIN villes v ON vl.ville_id = v.id
          WHERE l.is_active = 1
          GROUP BY l.id
          ORDER BY l.nom ASC";
$result = $conn->query($query);
?>
<div class="page-header">
    <div class="d-flex justify-content-between align-items-center">
        <div>
            <h1><i class="fas fa-motorcycle"></i> Gestion des Livreurs</h1>
            <p>Gérez vos livreurs et leurs disponibilités</p>
        </div>
        <button type="button" class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#modalAddLivreur">
            <i class="fas fa-plus"></i> Ajouter un livreur
        </button>
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

<div class="content-card">
    <div class="table-responsive">
        <table class="table table-hover">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Nom</th>
                    <th>Téléphone</th>
                    <th>Email</th>
                    <th>Villes</th>
                    <th>Commandes actuelles</th>
                    <th>Total commandes</th>
                    <th>Commandes terminées</th>
                    <th>Note moyenne</th>
                    <th>Statut</th>
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
                    <td><strong><?php echo htmlspecialchars($row['nom'] . ' ' . $row['prenom']); ?></strong></td>
                    <td><?php echo htmlspecialchars($row['telephone']); ?></td>
                    <td><?php echo htmlspecialchars($row['email'] ?? '-'); ?></td>
                    <td>
                        <?php if ($row['villes']): ?>
                            <span class="badge badge-info"><?php echo htmlspecialchars($row['villes']); ?></span>
                        <?php else: ?>
                            <span class="text-muted">Aucune</span>
                        <?php endif; ?>
                    </td>
                    <td><span class="badge badge-<?php echo $row['nombre_commandes_actuelles'] > 5 ? 'warning' : 'success'; ?>">
                        <?php echo $row['nombre_commandes_actuelles']; ?>
                    </span></td>
                    <td><?php echo $row['total_commandes']; ?></td>
                    <td><?php echo $row['commandes_terminees']; ?></td>
                    <td>
                        <?php if ($row['note_moyenne']): ?>
                            <?php echo number_format($row['note_moyenne'], 1); ?> / 5
                            <i class="fas fa-star text-warning"></i>
                        <?php else: ?>
                            <span class="text-muted">-</span>
                        <?php endif; ?>
                    </td>
                    <td>
                        <?php if ($row['is_available']): ?>
                            <span class="badge badge-success">Disponible</span>
                        <?php else: ?>
                            <span class="badge badge-danger">Indisponible</span>
                        <?php endif; ?>
                    </td>
                    <td>
                        <div class="btn-group">
                            <button type="button" class="btn btn-sm btn-warning" data-bs-toggle="modal" data-bs-target="#modalEditLivreur<?php echo $row['id']; ?>">
                                <i class="fas fa-edit"></i> Modifier
                            </button>
                            <button type="button" class="btn btn-sm btn-info" data-bs-toggle="modal" data-bs-target="#modalVillesLivreur<?php echo $row['id']; ?>">
                                <i class="fas fa-map-marker-alt"></i> Villes
                            </button>
                            <form method="POST" style="display: inline;">
                                <input type="hidden" name="csrf_token" value="<?php echo $_SESSION['csrf_token']; ?>">
                                <input type="hidden" name="toggle_availability" value="1">
                                <input type="hidden" name="livreur_id" value="<?php echo $row['id']; ?>">
                                <input type="hidden" name="is_available" value="<?php echo $row['is_available'] ? 0 : 1; ?>">
                                <button type="submit" class="btn btn-sm btn-<?php echo $row['is_available'] ? 'warning' : 'success'; ?>">
                                    <i class="fas fa-<?php echo $row['is_available'] ? 'ban' : 'check'; ?>"></i>
                                    <?php echo $row['is_available'] ? 'Désactiver' : 'Activer'; ?>
                                </button>
                            </form>
                            <a href="?section=statistiques&livreur_id=<?php echo $row['id']; ?>" class="btn btn-sm btn-info">
                                <i class="fas fa-chart-line"></i> Stats
                            </a>
                            <button type="button" 
                                    class="btn btn-sm btn-danger" 
                                    onclick="confirmDeleteLivreur(<?php echo $row['id']; ?>, '<?php echo htmlspecialchars($row['nom'] . ' ' . $row['prenom'], ENT_QUOTES); ?>')">
                                <i class="fas fa-trash"></i> Supprimer
                            </button>
                        </div>
                    </td>
                </tr>
                <?php
                    endwhile;
                else:
                ?>
                <tr>
                    <td colspan="11" class="text-center text-muted">Aucun livreur trouvé</td>
                </tr>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
</div>

<!-- Modal Ajouter Livreur -->
<div class="modal fade" id="modalAddLivreur" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <form method="POST" action="systeme_gestion.php?section=livreurs">
                <input type="hidden" name="csrf_token" value="<?php echo $_SESSION['csrf_token']; ?>">
                <input type="hidden" name="save_livreur" value="1">
                <div class="modal-header">
                    <h5 class="modal-title">Ajouter un livreur</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <div class="row">
                        <div class="col-md-6 mb-3">
                            <label class="form-label">Nom *</label>
                            <input type="text" class="form-control" name="nom" required>
                        </div>
                        <div class="col-md-6 mb-3">
                            <label class="form-label">Prénom *</label>
                            <input type="text" class="form-control" name="prenom" required>
                        </div>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Téléphone *</label>
                        <input type="text" class="form-control" name="telephone" placeholder="243812345678" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Email</label>
                        <input type="email" class="form-control" name="email" placeholder="livreur@soko.com">
                    </div>
                    <div class="row">
                        <div class="col-md-6 mb-3">
                            <div class="form-check">
                                <input class="form-check-input" type="checkbox" name="is_active" value="1" checked>
                                <label class="form-check-label">
                                    Livreur actif
                                </label>
                            </div>
                        </div>
                        <div class="col-md-6 mb-3">
                            <div class="form-check">
                                <input class="form-check-input" type="checkbox" name="is_available" value="1" checked>
                                <label class="form-check-label">
                                    Disponible
                                </label>
                            </div>
                        </div>
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

<!-- Modal Modifier Livreur (pour chaque livreur) -->
<?php
if ($result && $result->num_rows > 0):
    $result->data_seek(0); // Réinitialiser le pointeur
    while ($row = $result->fetch_assoc()):
?>
<div class="modal fade" id="modalEditLivreur<?php echo $row['id']; ?>" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <form method="POST" action="systeme_gestion.php?section=livreurs">
                <input type="hidden" name="csrf_token" value="<?php echo $_SESSION['csrf_token']; ?>">
                <input type="hidden" name="save_livreur" value="1">
                <input type="hidden" name="livreur_id" value="<?php echo $row['id']; ?>">
                <div class="modal-header">
                    <h5 class="modal-title">Modifier - <?php echo htmlspecialchars($row['nom'] . ' ' . $row['prenom']); ?></h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <div class="row">
                        <div class="col-md-6 mb-3">
                            <label class="form-label">Nom *</label>
                            <input type="text" class="form-control" name="nom" value="<?php echo htmlspecialchars($row['nom']); ?>" required>
                        </div>
                        <div class="col-md-6 mb-3">
                            <label class="form-label">Prénom *</label>
                            <input type="text" class="form-control" name="prenom" value="<?php echo htmlspecialchars($row['prenom']); ?>" required>
                        </div>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Téléphone *</label>
                        <input type="text" class="form-control" name="telephone" value="<?php echo htmlspecialchars($row['telephone']); ?>" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Email</label>
                        <input type="email" class="form-control" name="email" value="<?php echo htmlspecialchars($row['email'] ?? ''); ?>">
                    </div>
                    <div class="row">
                        <div class="col-md-6 mb-3">
                            <div class="form-check">
                                <input class="form-check-input" type="checkbox" name="is_active" value="1" <?php echo $row['is_active'] ? 'checked' : ''; ?>>
                                <label class="form-check-label">
                                    Livreur actif
                                </label>
                            </div>
                        </div>
                        <div class="col-md-6 mb-3">
                            <div class="form-check">
                                <input class="form-check-input" type="checkbox" name="is_available" value="1" <?php echo $row['is_available'] ? 'checked' : ''; ?>>
                                <label class="form-check-label">
                                    Disponible
                                </label>
                            </div>
                        </div>
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

<!-- Modal Gérer Villes du Livreur -->
<div class="modal fade" id="modalVillesLivreur<?php echo $row['id']; ?>" tabindex="-1">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">Villes assignées - <?php echo htmlspecialchars($row['nom'] . ' ' . $row['prenom']); ?></h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <h6>Villes actuellement assignées</h6>
                <?php
                $villes_query = "SELECT v.id, v.nom, vl.is_primary
                                FROM villes v
                                INNER JOIN ville_livreur vl ON v.id = vl.ville_id
                                WHERE vl.livreur_id = ? AND vl.is_active = 1
                                ORDER BY vl.is_primary DESC, v.nom ASC";
                $stmt_villes = $conn->prepare($villes_query);
                $stmt_villes->bind_param("i", $row['id']);
                $stmt_villes->execute();
                $villes_result = $stmt_villes->get_result();
                $villes_list = [];
                while ($vil = $villes_result->fetch_assoc()) {
                    $villes_list[] = $vil;
                }
                $stmt_villes->close();
                
                if (count($villes_list) > 0):
                ?>
                <table class="table table-sm">
                    <thead>
                        <tr>
                            <th>Ville</th>
                            <th>Type</th>
                            <th>Action</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($villes_list as $vil): ?>
                        <tr>
                            <td><?php echo htmlspecialchars($vil['nom']); ?></td>
                            <td>
                                <?php if ($vil['is_primary']): ?>
                                    <span class="badge badge-primary">Principal</span>
                                <?php else: ?>
                                    <span class="badge badge-secondary">Secondaire</span>
                                <?php endif; ?>
                            </td>
                            <td>
                                <form method="POST" style="display: inline;" onsubmit="return confirm('Êtes-vous sûr de vouloir retirer ce livreur de cette ville ?');">
                                    <input type="hidden" name="csrf_token" value="<?php echo $_SESSION['csrf_token']; ?>">
                                    <input type="hidden" name="remove_ville_livreur" value="1">
                                    <input type="hidden" name="ville_id" value="<?php echo $vil['id']; ?>">
                                    <input type="hidden" name="livreur_id" value="<?php echo $row['id']; ?>">
                                    <button type="submit" class="btn btn-sm btn-danger">
                                        <i class="fas fa-times"></i> Retirer
                                    </button>
                                </form>
                            </td>
                        </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
                <?php else: ?>
                <p class="text-muted">Aucune ville assignée à ce livreur</p>
                <?php endif; ?>
                
                <hr>
                <h6>Assigner une ville à ce livreur</h6>
                <form method="POST" action="systeme_gestion.php?section=livreurs" class="mt-3">
                    <input type="hidden" name="csrf_token" value="<?php echo $_SESSION['csrf_token']; ?>">
                    <input type="hidden" name="assign_ville_livreur" value="1">
                    <input type="hidden" name="livreur_id" value="<?php echo $row['id']; ?>">
                    <div class="mb-3">
                        <label class="form-label">Sélectionner une ville</label>
                        <select name="ville_id" class="form-select" required>
                            <option value="">-- Choisir une ville --</option>
                            <?php
                            $all_villes = $conn->query("SELECT id, nom FROM villes WHERE is_active = 1 ORDER BY nom ASC");
                            while ($vil = $all_villes->fetch_assoc()):
                                // Vérifier si déjà assigné
                                $check_assigned = $conn->prepare("SELECT id FROM ville_livreur WHERE livreur_id = ? AND ville_id = ?");
                                $check_assigned->bind_param("ii", $row['id'], $vil['id']);
                                $check_assigned->execute();
                                $already_assigned = $check_assigned->get_result()->num_rows > 0;
                                $check_assigned->close();
                            ?>
                                <option value="<?php echo $vil['id']; ?>" <?php echo $already_assigned ? 'disabled' : ''; ?>>
                                    <?php echo htmlspecialchars($vil['nom']); ?>
                                    <?php echo $already_assigned ? '(déjà assigné)' : ''; ?>
                                </option>
                            <?php endwhile; ?>
                        </select>
                    </div>
                    <div class="mb-3">
                        <div class="form-check">
                            <input class="form-check-input" type="checkbox" name="is_primary" value="1">
                            <label class="form-check-label">
                                Livreur principal pour cette ville
                            </label>
                        </div>
                    </div>
                    <button type="submit" class="btn btn-primary">
                        <i class="fas fa-plus"></i> Assigner
                    </button>
                </form>
            </div>
        </div>
    </div>
</div>
<?php
    endwhile;
endif;
?>

<script>
// 💡 NOUVEAU : Fonction pour confirmer la suppression d'un livreur
function confirmDeleteLivreur(livreurId, livreurNom) {
    if (confirm('Êtes-vous sûr de vouloir supprimer le livreur "' + livreurNom + '" ?\n\nCette action désactivera le livreur et toutes ses associations avec les villes.')) {
        // Créer un formulaire pour envoyer la requête POST
        const form = document.createElement('form');
        form.method = 'POST';
        form.action = 'systeme_gestion.php?section=livreurs';
        
        // Ajouter le token CSRF
        const csrfInput = document.createElement('input');
        csrfInput.type = 'hidden';
        csrfInput.name = 'csrf_token';
        csrfInput.value = '<?php echo $_SESSION['csrf_token']; ?>';
        form.appendChild(csrfInput);
        
        // Ajouter l'action
        const actionInput = document.createElement('input');
        actionInput.type = 'hidden';
        actionInput.name = 'delete_livreur';
        actionInput.value = '1';
        form.appendChild(actionInput);
        
        // Ajouter l'ID du livreur
        const idInput = document.createElement('input');
        idInput.type = 'hidden';
        idInput.name = 'livreur_id';
        idInput.value = livreurId;
        form.appendChild(idInput);
        
        // Ajouter le formulaire au body et le soumettre
        document.body.appendChild(form);
        form.submit();
    }
}
</script>
