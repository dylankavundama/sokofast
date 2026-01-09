<?php
// logs.php - Affichage des logs et erreurs

// Définir les fichiers de logs à surveiller
$log_files = [
    'error_log' => [
        'name' => 'Logs PHP (error_log)',
        'path' => __DIR__ . '/../error_log',
        'icon' => 'fas fa-bug'
    ],
    'flexpay_callback' => [
        'name' => 'Logs FlexPay Callback',
        'path' => __DIR__ . '/../flexpay_callback.log',
        'icon' => 'fas fa-credit-card'
    ]
];

// Fonction pour lire les dernières lignes d'un fichier
function readLogFile($file_path, $lines = 100) {
    if (!file_exists($file_path)) {
        return ['content' => '', 'error' => 'Fichier non trouvé', 'size' => 0, 'modified' => null];
    }
    
    $file_size = filesize($file_path);
    $modified = filemtime($file_path);
    
    if ($file_size === 0) {
        return ['content' => 'Fichier vide', 'error' => null, 'size' => 0, 'modified' => $modified];
    }
    
    try {
        $content = file_get_contents($file_path);
        if ($content === false) {
            return ['content' => '', 'error' => 'Impossible de lire le fichier', 'size' => $file_size, 'modified' => $modified];
        }
        
        // Découper en lignes et prendre les N dernières
        $all_lines = explode("\n", $content);
        $total_lines = count($all_lines);
        $start_line = max(0, $total_lines - $lines);
        $selected_lines = array_slice($all_lines, $start_line);
        
        return [
            'content' => implode("\n", $selected_lines),
            'error' => null,
            'size' => $file_size,
            'modified' => $modified,
            'total_lines' => $total_lines,
            'showing_lines' => count($selected_lines)
        ];
    } catch (Exception $e) {
        return ['content' => '', 'error' => $e->getMessage(), 'size' => $file_size, 'modified' => $modified];
    }
}

// Fonction pour formater la taille du fichier
function formatFileSize($bytes) {
    if ($bytes >= 1073741824) {
        return number_format($bytes / 1073741824, 2) . ' GB';
    } elseif ($bytes >= 1048576) {
        return number_format($bytes / 1048576, 2) . ' MB';
    } elseif ($bytes >= 1024) {
        return number_format($bytes / 1024, 2) . ' KB';
    } else {
        return $bytes . ' bytes';
    }
}

// Traitement des actions
$action = $_GET['action'] ?? '';
$log_file_key = $_GET['log'] ?? '';

if ($action === 'clear' && isset($log_files[$log_file_key])) {
    $log_path = $log_files[$log_file_key]['path'];
    if (file_exists($log_path) && is_writable($log_path)) {
        if (@file_put_contents($log_path, '') !== false) {
            $message = "Le fichier de log a été vidé avec succès.";
        } else {
            $error = "Impossible de vider le fichier de log (permissions insuffisantes).";
        }
    } else {
        $error = "Impossible de vider le fichier de log (fichier non trouvé ou non accessible).";
    }
}

// Téléchargement de log
if ($action === 'download' && isset($log_files[$log_file_key])) {
    $log_path = $log_files[$log_file_key]['path'];
    if (file_exists($log_path) && is_readable($log_path)) {
        header('Content-Type: text/plain; charset=utf-8');
        header('Content-Disposition: attachment; filename="' . basename($log_path) . '_' . date('Y-m-d_His') . '.txt"');
        header('Content-Length: ' . filesize($log_path));
        header('Cache-Control: must-revalidate');
        header('Pragma: public');
        readfile($log_path);
        exit;
    } else {
        $error = "Impossible de télécharger le fichier de log (fichier non trouvé ou non accessible).";
    }
}

// Récupérer le nombre de lignes à afficher
$lines_to_show = isset($_GET['lines']) ? (int)$_GET['lines'] : 100;
$lines_to_show = max(10, min(1000, $lines_to_show)); // Entre 10 et 1000

// Lire les logs
$logs_data = [];
foreach ($log_files as $key => $log_info) {
    $logs_data[$key] = readLogFile($log_info['path'], $lines_to_show);
    $logs_data[$key]['name'] = $log_info['name'];
    $logs_data[$key]['icon'] = $log_info['icon'];
}
?>

<div class="page-header">
    <h1><i class="fas fa-exclamation-triangle"></i> Logs & Erreurs</h1>
    <p>Surveillance et gestion des logs système</p>
</div>

<?php if (isset($message)): ?>
    <div class="alert alert-success alert-dismissible fade show" role="alert">
        <i class="fas fa-check-circle"></i> <?php echo htmlspecialchars($message); ?>
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
<?php endif; ?>

<?php if (isset($error)): ?>
    <div class="alert alert-danger alert-dismissible fade show" role="alert">
        <i class="fas fa-exclamation-circle"></i> <?php echo htmlspecialchars($error); ?>
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
<?php endif; ?>

<!-- Contrôles -->
<div class="content-card mb-3">
    <div class="row align-items-center">
        <div class="col-md-6">
            <label class="form-label">Nombre de lignes à afficher :</label>
            <select id="linesSelect" class="form-select" onchange="updateLines(this.value)">
                <option value="50" <?php echo $lines_to_show == 50 ? 'selected' : ''; ?>>50 lignes</option>
                <option value="100" <?php echo $lines_to_show == 100 ? 'selected' : ''; ?>>100 lignes</option>
                <option value="200" <?php echo $lines_to_show == 200 ? 'selected' : ''; ?>>200 lignes</option>
                <option value="500" <?php echo $lines_to_show == 500 ? 'selected' : ''; ?>>500 lignes</option>
                <option value="1000" <?php echo $lines_to_show == 1000 ? 'selected' : ''; ?>>1000 lignes</option>
            </select>
        </div>
        <div class="col-md-6 text-end">
            <button type="button" class="btn btn-primary" onclick="location.reload()">
                <i class="fas fa-sync-alt"></i> Actualiser
            </button>
        </div>
    </div>
</div>

<!-- Affichage des logs -->
<?php foreach ($logs_data as $key => $log_data): ?>
    <div class="content-card mb-4">
        <div class="d-flex justify-content-between align-items-center mb-3">
            <h2>
                <i class="<?php echo htmlspecialchars($log_data['icon']); ?>"></i> 
                <?php echo htmlspecialchars($log_data['name']); ?>
            </h2>
            <div class="btn-group">
                <?php if ($log_data['size'] > 0): ?>
                    <a href="?section=logs&action=clear&log=<?php echo $key; ?>" 
                       class="btn btn-sm btn-danger" 
                       onclick="return confirm('Êtes-vous sûr de vouloir vider ce fichier de log ?');">
                        <i class="fas fa-trash"></i> Vider
                    </a>
                <?php endif; ?>
                <button type="button" class="btn btn-sm btn-secondary" onclick="downloadLog('<?php echo $key; ?>')">
                    <i class="fas fa-download"></i> Télécharger
                </button>
            </div>
        </div>
        
        <!-- Informations du fichier -->
        <div class="row mb-3">
            <div class="col-md-3">
                <small class="text-muted">
                    <i class="fas fa-file"></i> Taille : 
                    <strong><?php echo formatFileSize($log_data['size']); ?></strong>
                </small>
            </div>
            <div class="col-md-3">
                <small class="text-muted">
                    <i class="fas fa-clock"></i> Dernière modification : 
                    <strong>
                        <?php 
                        if ($log_data['modified']) {
                            echo date('d/m/Y H:i:s', $log_data['modified']);
                        } else {
                            echo 'N/A';
                        }
                        ?>
                    </strong>
                </small>
            </div>
            <?php if (isset($log_data['total_lines'])): ?>
            <div class="col-md-3">
                <small class="text-muted">
                    <i class="fas fa-list"></i> Lignes totales : 
                    <strong><?php echo number_format($log_data['total_lines']); ?></strong>
                </small>
            </div>
            <div class="col-md-3">
                <small class="text-muted">
                    <i class="fas fa-eye"></i> Affichage : 
                    <strong><?php echo number_format($log_data['showing_lines'] ?? 0); ?> lignes</strong>
                </small>
            </div>
            <?php endif; ?>
        </div>
        
        <!-- Contenu du log -->
        <div class="log-container">
            <?php if ($log_data['error']): ?>
                <div class="alert alert-warning">
                    <i class="fas fa-exclamation-triangle"></i> 
                    <?php echo htmlspecialchars($log_data['error']); ?>
                </div>
            <?php elseif (empty($log_data['content']) || $log_data['content'] === 'Fichier vide'): ?>
                <div class="alert alert-info">
                    <i class="fas fa-info-circle"></i> 
                    <?php echo $log_data['content'] ?: 'Aucune entrée dans ce fichier de log.'; ?>
                </div>
            <?php else: ?>
                <div class="log-content">
                    <pre class="log-text"><?php echo htmlspecialchars($log_data['content']); ?></pre>
                </div>
            <?php endif; ?>
        </div>
    </div>
<?php endforeach; ?>

<style>
    .log-container {
        background: #1e1e1e;
        border-radius: 8px;
        padding: 15px;
        max-height: 600px;
        overflow-y: auto;
        border: 1px solid #dee2e6;
    }
    
    .log-content {
        margin: 0;
    }
    
    .log-text {
        color: #d4d4d4;
        background: transparent;
        border: none;
        font-family: 'Courier New', monospace;
        font-size: 0.85em;
        line-height: 1.6;
        margin: 0;
        padding: 0;
        white-space: pre-wrap;
        word-wrap: break-word;
    }
    
    /* Styles pour les erreurs dans les logs */
    .log-text {
        color: #d4d4d4;
    }
    
    /* Scrollbar personnalisée */
    .log-container::-webkit-scrollbar {
        width: 8px;
    }
    
    .log-container::-webkit-scrollbar-track {
        background: #2d2d2d;
        border-radius: 4px;
    }
    
    .log-container::-webkit-scrollbar-thumb {
        background: #555;
        border-radius: 4px;
    }
    
    .log-container::-webkit-scrollbar-thumb:hover {
        background: #777;
    }
    
    @media (max-width: 768px) {
        .log-container {
            max-height: 400px;
            padding: 10px;
        }
        
        .log-text {
            font-size: 0.75em;
        }
    }
</style>

<script>
    function updateLines(lines) {
        const url = new URL(window.location);
        url.searchParams.set('lines', lines);
        window.location.href = url.toString();
    }
    
    function downloadLog(logKey) {
        // Créer un lien de téléchargement
        const url = `?section=logs&action=download&log=${logKey}`;
        window.location.href = url;
    }
    
    // Auto-refresh optionnel (toutes les 30 secondes)
    // Décommentez si vous voulez l'auto-refresh
    // setInterval(function() {
    //     location.reload();
    // }, 30000);
</script>

