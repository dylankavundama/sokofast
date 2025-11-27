<?php
// villes.php - Gestion des villes

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
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action']) && (!isset($processing_post_only) || $processing_post_only)) {
    if (!isset($_POST['csrf_token']) || $_POST['csrf_token'] !== $_SESSION['csrf_token']) {
        $error = "Erreur de sécurité : Jeton CSRF invalide.";
    } else {
        if ($_POST['action'] === 'save_ville') {
            // Sauvegarder une ville (ajout ou modification)
            $data = [
                'nom' => $_POST['nom'],
                'code_postal' => $_POST['code_postal'] ?? '',
                'latitude' => !empty($_POST['latitude']) ? $_POST['latitude'] : null,
                'longitude' => !empty($_POST['longitude']) ? $_POST['longitude'] : null,
                'is_active' => isset($_POST['is_active']) ? 1 : 0
            ];
            
            if (isset($_POST['ville_id']) && !empty($_POST['ville_id'])) {
                $data['id'] = (int)$_POST['ville_id'];
            }
            
            // Construire l'URL du backend
            $url = getBackendURL('add_ville.php');
            $result = callInternalAPI($url, $data, 'POST');
            
            if ($result['success'] && $result['data'] && isset($result['data']['message'])) {
                $message = $result['data']['message'];
                header("Location: systeme_gestion.php?section=villes&message=" . urlencode($message));
                exit();
            } else {
                $error = $result['error'] ?? ($result['data']['message'] ?? 'Erreur lors de la sauvegarde');
                error_log("Erreur sauvegarde ville: " . $error);
            }
        } elseif ($_POST['action'] === 'assign_livreur') {
            // Assigner un livreur à une ville
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
                header("Location: systeme_gestion.php?section=villes&message=" . urlencode($message));
                exit();
            } else {
                $error = $result['error'] ?? ($result['data']['message'] ?? 'Erreur lors de l\'assignation');
                error_log("Erreur assignation livreur: " . $error);
            }
        } elseif ($_POST['action'] === 'remove_livreur') {
            // Retirer un livreur d'une ville
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
                header("Location: systeme_gestion.php?section=villes&message=" . urlencode($message));
                exit();
            } else {
                $error = $result['error'] ?? ($result['data']['message'] ?? 'Erreur lors de la suppression');
                error_log("Erreur suppression livreur: " . $error);
            }
        } elseif ($_POST['action'] === 'delete_ville') {
            // 💡 NOUVEAU : Supprimer une ville
            $data = [
                'id' => (int)$_POST['ville_id'],
                'action' => 'delete'
            ];
            
            // Construire l'URL du backend
            $url = getBackendURL('add_ville.php');
            $result = callInternalAPI($url, $data, 'POST');
            
            if ($result['success'] && $result['data'] && isset($result['data']['message'])) {
                $message = $result['data']['message'];
                header("Location: systeme_gestion.php?section=villes&message=" . urlencode($message));
                exit();
            } else {
                $error = $result['error'] ?? ($result['data']['message'] ?? 'Erreur lors de la suppression de la ville');
                error_log("Erreur suppression ville: " . $error);
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

// Récupération des villes avec statistiques
$query = "SELECT v.*, 
                 COUNT(DISTINCT vl.livreur_id) as nombre_livreurs,
                 COUNT(c.id) as nombre_commandes
          FROM villes v
          LEFT JOIN ville_livreur vl ON v.id = vl.ville_id
          LEFT JOIN commandes c ON v.id = c.ville_id
          WHERE v.is_active = 1
          GROUP BY v.id
          ORDER BY v.nom ASC";
$result = $conn->query($query);
?>
<div class="page-header">
    <div class="d-flex justify-content-between align-items-center">
        <div>
            <h1><i class="fas fa-map-marker-alt"></i> Gestion des Villes</h1>
            <p>Gérez les villes de livraison et leurs livreurs</p>
        </div>
        <button type="button" class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#modalAddVille">
            <i class="fas fa-plus"></i> Ajouter une ville
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

<!-- 💡 NOUVEAU : Statistiques globales -->
<?php
$total_villes = $result ? $result->num_rows : 0;
$total_livreurs_assignes = 0;
$total_commandes_villes = 0;
if ($result && $result->num_rows > 0) {
    $result->data_seek(0);
    while ($row = $result->fetch_assoc()) {
        $total_livreurs_assignes += $row['nombre_livreurs'];
        $total_commandes_villes += $row['nombre_commandes'];
    }
    $result->data_seek(0); // Réinitialiser pour l'affichage
}
?>
<div class="stats-grid mb-4">
    <div class="stat-card info">
        <div class="icon"><i class="fas fa-city"></i></div>
        <h3><?php echo $total_villes; ?></h3>
        <p>Villes actives</p>
    </div>
    <div class="stat-card success">
        <div class="icon"><i class="fas fa-motorcycle"></i></div>
        <h3><?php echo $total_livreurs_assignes; ?></h3>
        <p>Livreurs assignés</p>
    </div>
    <div class="stat-card primary">
        <div class="icon"><i class="fas fa-shopping-cart"></i></div>
        <h3><?php echo $total_commandes_villes; ?></h3>
        <p>Commandes totales</p>
    </div>
</div>

<!-- 💡 NOUVEAU : Affichage en cartes au lieu de tableau -->
<div class="row g-3" id="villes-grid">
    <?php
    if ($result && $result->num_rows > 0):
        while ($row = $result->fetch_assoc()):
            // Récupérer le nombre de livreurs principaux
            $query_principaux = "SELECT COUNT(*) as nb FROM ville_livreur WHERE ville_id = ? AND is_primary = 1 AND is_active = 1";
            $stmt_princ = $conn->prepare($query_principaux);
            $stmt_princ->bind_param("i", $row['id']);
            $stmt_princ->execute();
            $nb_principaux = $stmt_princ->get_result()->fetch_assoc()['nb'];
            $stmt_princ->close();
    ?>
    <div class="col-md-6 col-lg-4">
        <div class="card ville-card h-100 shadow-sm">
            <div class="card-header bg-primary text-white d-flex justify-content-between align-items-center">
                <div>
                    <h5 class="mb-0">
                        <i class="fas fa-map-marker-alt me-2"></i>
                        <?php echo htmlspecialchars($row['nom']); ?>
                    </h5>
                    <?php if ($row['code_postal']): ?>
                        <small class="text-white-50">Code: <?php echo htmlspecialchars($row['code_postal']); ?></small>
                    <?php endif; ?>
                </div>
                <?php if ($row['is_active']): ?>
                    <span class="badge bg-success">Active</span>
                <?php else: ?>
                    <span class="badge bg-danger">Inactive</span>
                <?php endif; ?>
            </div>
            <div class="card-body">
                <!-- Coordonnées GPS -->
                <div class="mb-3">
                    <?php if ($row['latitude'] && $row['longitude']): ?>
                        <a href="https://maps.google.com/?q=<?php echo $row['latitude']; ?>,<?php echo $row['longitude']; ?>" 
                           target="_blank" 
                           class="btn btn-sm btn-outline-primary w-100">
                            <i class="fas fa-map-marked-alt"></i> Voir sur la carte
                        </a>
                        <small class="text-muted d-block mt-1 text-center">
                            <?php echo number_format($row['latitude'], 6); ?>, <?php echo number_format($row['longitude'], 6); ?>
                        </small>
                    <?php else: ?>
                        <span class="text-muted">
                            <i class="fas fa-exclamation-triangle"></i> Coordonnées non définies
                        </span>
                    <?php endif; ?>
                </div>
                
                <hr class="my-3">
                
                <!-- Statistiques -->
                <div class="row g-2 mb-3">
                    <div class="col-6">
                        <div class="stat-mini-card text-center p-2 bg-light rounded">
                            <div class="text-primary fw-bold fs-5"><?php echo $row['nombre_livreurs']; ?></div>
                            <small class="text-muted">Livreur(s)</small>
                            <?php if ($nb_principaux > 0): ?>
                                <div class="mt-1">
                                    <span class="badge bg-primary"><?php echo $nb_principaux; ?> principal<?php echo $nb_principaux > 1 ? 'aux' : ''; ?></span>
                                </div>
                            <?php endif; ?>
                        </div>
                    </div>
                    <div class="col-6">
                        <div class="stat-mini-card text-center p-2 bg-light rounded">
                            <div class="text-success fw-bold fs-5"><?php echo $row['nombre_commandes']; ?></div>
                            <small class="text-muted">Commande(s)</small>
                        </div>
                    </div>
                </div>
                
                <!-- Alerte si pas assez de livreurs -->
                <?php if ($row['nombre_livreurs'] < 2): ?>
                    <div class="alert alert-warning py-2 px-3 mb-3">
                        <small><i class="fas fa-exclamation-triangle"></i> Moins de 2 livreurs assignés</small>
                    </div>
                <?php endif; ?>
                
                <!-- Alerte si pas de livreur principal -->
                <?php if ($nb_principaux == 0 && $row['nombre_livreurs'] > 0): ?>
                    <div class="alert alert-info py-2 px-3 mb-3">
                        <small><i class="fas fa-info-circle"></i> Aucun livreur principal défini</small>
                    </div>
                <?php endif; ?>
            </div>
            <div class="card-footer bg-white">
                <div class="d-grid gap-2 d-md-flex">
                    <button type="button" 
                            class="btn btn-sm btn-info flex-fill" 
                            data-bs-toggle="modal" 
                            data-bs-target="#modalVille<?php echo $row['id']; ?>">
                        <i class="fas fa-eye"></i> Détails
                    </button>
                    <button type="button" 
                            class="btn btn-sm btn-warning flex-fill" 
                            data-bs-toggle="modal" 
                            data-bs-target="#modalEditVille<?php echo $row['id']; ?>">
                        <i class="fas fa-edit"></i> Modifier
                    </button>
                    <button type="button" 
                            class="btn btn-sm btn-danger flex-fill" 
                            onclick="confirmDeleteVille(<?php echo $row['id']; ?>, '<?php echo htmlspecialchars($row['nom'], ENT_QUOTES); ?>')">
                        <i class="fas fa-trash"></i> Supprimer
                    </button>
                </div>
            </div>
        </div>
    </div>

                <!-- Modal Détails Ville -->
                <div class="modal fade" id="modalVille<?php echo $row['id']; ?>" tabindex="-1">
                    <div class="modal-dialog modal-lg">
                        <div class="modal-content">
                            <div class="modal-header">
                                <h5 class="modal-title">Détails - <?php echo htmlspecialchars($row['nom']); ?></h5>
                                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                            </div>
                            <div class="modal-body">
                                <h6>Livreurs assignés</h6>
                                <?php
                                $livreurs_query = "SELECT l.id, l.nom, l.prenom, l.telephone, l.is_available, l.nombre_commandes_actuelles, vl.is_primary
                                                  FROM livreurs l
                                                  INNER JOIN ville_livreur vl ON l.id = vl.livreur_id
                                                  WHERE vl.ville_id = ?
                                                  ORDER BY vl.is_primary DESC, l.nom ASC";
                                $stmt_liv = $conn->prepare($livreurs_query);
                                $stmt_liv->bind_param("i", $row['id']);
                                $stmt_liv->execute();
                                $livreurs_result = $stmt_liv->get_result();
                                $livreurs_list = [];
                                while ($liv = $livreurs_result->fetch_assoc()) {
                                    $livreurs_list[] = $liv;
                                }
                                $stmt_liv->close();
                                
                                if (count($livreurs_list) > 0):
                                ?>
                                <table class="table table-sm">
                                    <thead>
                                        <tr>
                                            <th>Nom</th>
                                            <th>Téléphone</th>
                                            <th>Commandes actuelles</th>
                                            <th>Statut</th>
                                            <th>Type</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <?php foreach ($livreurs_list as $liv): ?>
                                        <tr>
                                            <td><?php echo htmlspecialchars($liv['nom'] . ' ' . $liv['prenom']); ?></td>
                                            <td><?php echo htmlspecialchars($liv['telephone']); ?></td>
                                            <td><?php echo $liv['nombre_commandes_actuelles']; ?></td>
                                            <td>
                                                <?php if ($liv['is_available']): ?>
                                                    <span class="badge badge-success">Disponible</span>
                                                <?php else: ?>
                                                    <span class="badge badge-danger">Indisponible</span>
                                                <?php endif; ?>
                                            </td>
                                            <td>
                                                <?php if ($liv['is_primary']): ?>
                                                    <span class="badge badge-primary">Principal</span>
                                                <?php else: ?>
                                                    <span class="badge badge-secondary">Secondaire</span>
                                                <?php endif; ?>
                                            </td>
                                        </tr>
                                        <?php endforeach; ?>
                                    </tbody>
                                </table>
                                <?php else: ?>
                                <p class="text-muted">Aucun livreur assigné à cette ville</p>
                                <?php endif; ?>
                                
                                <hr>
                                <h6>Assigner un livreur à cette ville</h6>
                                <form method="POST" action="systeme_gestion.php?section=villes" class="mt-3">
                                    <input type="hidden" name="csrf_token" value="<?php echo $_SESSION['csrf_token']; ?>">
                                    <input type="hidden" name="action" value="assign_livreur">
                                    <input type="hidden" name="ville_id" value="<?php echo $row['id']; ?>">
                                    <div class="mb-3">
                                        <label class="form-label">Sélectionner un livreur</label>
                                        <select name="livreur_id" class="form-select" required>
                                            <option value="">-- Choisir un livreur --</option>
                                            <?php
                                            $all_livreurs = $conn->query("SELECT id, nom, prenom FROM livreurs WHERE is_active = 1 ORDER BY nom ASC");
                                            while ($liv = $all_livreurs->fetch_assoc()):
                                                // Vérifier si déjà assigné
                                                $check_assigned = $conn->prepare("SELECT id FROM ville_livreur WHERE ville_id = ? AND livreur_id = ?");
                                                $check_assigned->bind_param("ii", $row['id'], $liv['id']);
                                                $check_assigned->execute();
                                                $already_assigned = $check_assigned->get_result()->num_rows > 0;
                                                $check_assigned->close();
                                            ?>
                                                <option value="<?php echo $liv['id']; ?>" <?php echo $already_assigned ? 'disabled' : ''; ?>>
                                                    <?php echo htmlspecialchars($liv['nom'] . ' ' . $liv['prenom']); ?>
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
                                        <i class="fas fa-user-plus"></i> Assigner
                                    </button>
                                </form>
                                
                                <?php if (count($livreurs_list) > 0): ?>
                                <hr>
                                <h6>Retirer un livreur</h6>
                                <form method="POST" action="systeme_gestion.php?section=villes" class="mt-3" onsubmit="return confirm('Êtes-vous sûr de vouloir retirer ce livreur de cette ville ?');">
                                    <input type="hidden" name="csrf_token" value="<?php echo $_SESSION['csrf_token']; ?>">
                                    <input type="hidden" name="action" value="remove_livreur">
                                    <input type="hidden" name="ville_id" value="<?php echo $row['id']; ?>">
                                    <div class="mb-3">
                                        <label class="form-label">Sélectionner un livreur à retirer</label>
                                        <select name="livreur_id" class="form-select" required>
                                            <option value="">-- Choisir un livreur --</option>
                                            <?php foreach ($livreurs_list as $liv): ?>
                                                <option value="<?php echo $liv['id']; ?>">
                                                    <?php echo htmlspecialchars($liv['nom'] . ' ' . $liv['prenom']); ?>
                                                </option>
                                            <?php endforeach; ?>
                                        </select>
                                    </div>
                                    <button type="submit" class="btn btn-danger">
                                        <i class="fas fa-user-minus"></i> Retirer
                                    </button>
                                </form>
                                <?php endif; ?>
                            </div>
                        </div>
                    </div>
                </div>
    <?php
        endwhile;
    else:
    ?>
    <div class="col-12">
        <div class="card text-center py-5">
            <div class="card-body">
                <i class="fas fa-city fa-3x text-muted mb-3"></i>
                <h5 class="text-muted">Aucune ville trouvée</h5>
                <p class="text-muted">Commencez par ajouter une ville de livraison</p>
                <button type="button" class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#modalAddVille">
                    <i class="fas fa-plus"></i> Ajouter une ville
                </button>
            </div>
        </div>
    </div>
    <?php endif; ?>
</div>

<style>
/* 💡 NOUVEAU : Styles pour les cartes de villes */
.ville-card {
    transition: transform 0.2s ease, box-shadow 0.2s ease;
    border: none;
    border-radius: 12px;
}

.ville-card:hover {
    transform: translateY(-5px);
    box-shadow: 0 8px 25px rgba(0,0,0,0.15) !important;
}

.ville-card .card-header {
    border-radius: 12px 12px 0 0 !important;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
    border: none;
}

.ville-card .card-body {
    padding: 1.25rem;
}

.ville-card .card-footer {
    border-top: 1px solid #e9ecef;
    border-radius: 0 0 12px 12px;
    padding: 0.75rem;
}

.stat-mini-card {
    transition: background-color 0.2s ease;
}

.stat-mini-card:hover {
    background-color: #f8f9fa !important;
}

/* Responsive pour les cartes */
@media (max-width: 768px) {
    #villes-grid .col-md-6 {
        margin-bottom: 1rem;
    }
}

@media (max-width: 576px) {
    .stats-grid {
        grid-template-columns: 1fr;
    }
    
    #villes-grid .col-lg-4 {
        margin-bottom: 1rem;
    }
}
</style>

<!-- Modal Ajouter/Modifier Ville -->
<div class="modal fade" id="modalAddVille" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <form id="formVille" method="POST" action="systeme_gestion.php?section=villes">
                <input type="hidden" name="csrf_token" value="<?php echo $_SESSION['csrf_token']; ?>">
                <input type="hidden" name="action" value="save_ville">
                <input type="hidden" name="ville_id" id="ville_id" value="">
                <div class="modal-header">
                    <h5 class="modal-title" id="modalVilleTitle">Ajouter une ville</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <div class="mb-3">
                        <label class="form-label">Nom de la ville *</label>
                        <input type="text" class="form-control" name="nom" id="ville_nom" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Code postal</label>
                        <input type="text" class="form-control" name="code_postal" id="ville_code_postal">
                    </div>
                    <div class="row">
                        <div class="col-md-6 mb-3">
                            <label class="form-label">Latitude</label>
                            <input type="number" step="any" class="form-control" name="latitude" id="ville_latitude">
                        </div>
                        <div class="col-md-6 mb-3">
                            <label class="form-label">Longitude</label>
                            <input type="number" step="any" class="form-control" name="longitude" id="ville_longitude">
                        </div>
                    </div>
                    <div class="mb-3">
                        <div class="form-check">
                            <input class="form-check-input" type="checkbox" name="is_active" id="ville_is_active" value="1" checked>
                            <label class="form-check-label" for="ville_is_active">
                                Ville active
                            </label>
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

<!-- Modal Modifier Ville (pour chaque ville) -->
<?php
if ($result && $result->num_rows > 0):
    $result->data_seek(0); // Réinitialiser le pointeur
    while ($row = $result->fetch_assoc()):
?>
<div class="modal fade" id="modalEditVille<?php echo $row['id']; ?>" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <form method="POST" action="systeme_gestion.php?section=villes">
                <input type="hidden" name="csrf_token" value="<?php echo $_SESSION['csrf_token']; ?>">
                <input type="hidden" name="action" value="save_ville">
                <input type="hidden" name="ville_id" value="<?php echo $row['id']; ?>">
                <div class="modal-header">
                    <h5 class="modal-title">Modifier - <?php echo htmlspecialchars($row['nom']); ?></h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <div class="mb-3">
                        <label class="form-label">Nom de la ville *</label>
                        <input type="text" class="form-control" name="nom" value="<?php echo htmlspecialchars($row['nom']); ?>" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Code postal</label>
                        <input type="text" class="form-control" name="code_postal" value="<?php echo htmlspecialchars($row['code_postal'] ?? ''); ?>">
                    </div>
                    <div class="row">
                        <div class="col-md-6 mb-3">
                            <label class="form-label">Latitude</label>
                            <input type="number" step="any" class="form-control" name="latitude" value="<?php echo $row['latitude'] ?? ''; ?>">
                        </div>
                        <div class="col-md-6 mb-3">
                            <label class="form-label">Longitude</label>
                            <input type="number" step="any" class="form-control" name="longitude" value="<?php echo $row['longitude'] ?? ''; ?>">
                        </div>
                    </div>
                    <div class="mb-3">
                        <div class="form-check">
                            <input class="form-check-input" type="checkbox" name="is_active" value="1" <?php echo $row['is_active'] ? 'checked' : ''; ?>>
                            <label class="form-check-label">
                                Ville active
                            </label>
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
<?php
    endwhile;
endif;
?>

<script>
// Fonction pour ouvrir le modal d'édition avec les données pré-remplies
function editVille(id, nom, codePostal, latitude, longitude, isActive) {
    document.getElementById('ville_id').value = id;
    document.getElementById('ville_nom').value = nom;
    document.getElementById('ville_code_postal').value = codePostal || '';
    document.getElementById('ville_latitude').value = latitude || '';
    document.getElementById('ville_longitude').value = longitude || '';
    document.getElementById('ville_is_active').checked = isActive == 1;
    document.getElementById('modalVilleTitle').textContent = 'Modifier la ville';
    
    const modal = new bootstrap.Modal(document.getElementById('modalAddVille'));
    modal.show();
}

// 💡 NOUVEAU : Fonction pour confirmer la suppression d'une ville
function confirmDeleteVille(villeId, villeNom) {
    if (confirm('Êtes-vous sûr de vouloir supprimer la ville "' + villeNom + '" ?\n\nCette action désactivera la ville et toutes ses associations avec les livreurs.')) {
        // Créer un formulaire pour envoyer la requête POST
        const form = document.createElement('form');
        form.method = 'POST';
        form.action = 'systeme_gestion.php?section=villes';
        
        // Ajouter le token CSRF
        const csrfInput = document.createElement('input');
        csrfInput.type = 'hidden';
        csrfInput.name = 'csrf_token';
        csrfInput.value = '<?php echo $_SESSION['csrf_token']; ?>';
        form.appendChild(csrfInput);
        
        // Ajouter l'action
        const actionInput = document.createElement('input');
        actionInput.type = 'hidden';
        actionInput.name = 'action';
        actionInput.value = 'delete_ville';
        form.appendChild(actionInput);
        
        // Ajouter l'ID de la ville
        const idInput = document.createElement('input');
        idInput.type = 'hidden';
        idInput.name = 'ville_id';
        idInput.value = villeId;
        form.appendChild(idInput);
        
        // Ajouter le formulaire au body et le soumettre
        document.body.appendChild(form);
        form.submit();
    }
}
</script>

