<?php
// systeme_gestion.php - Système de Gestion Complet
session_start();

// Vérification de la connexion
if (!isset($_SESSION['loggedin']) || $_SESSION['loggedin'] !== true) {
    header('Location: login.php');
    exit;
}

// Gestion de la déconnexion
if (isset($_GET['action']) && $_GET['action'] === 'logout') {
    session_unset();
    session_destroy();
    header('Location: login.php');
    exit;
}

require_once 'db_connection.php';
$conn->set_charset("utf8mb4");

// Variables globales
$message = '';
$error = '';
$current_section = $_GET['section'] ?? 'dashboard';

// Récupération des statistiques pour le tableau de bord
$stats = [
    'total_commandes' => 0,
    'commandes_en_cours' => 0,
    'commandes_terminees' => 0,
    'total_livreurs' => 0,
    'livreurs_disponibles' => 0,
    'total_villes' => 0,
    'commandes_sans_livreur' => 0
];

if ($conn && !$conn->connect_error) {
    // Statistiques commandes
    $result = $conn->query("SELECT COUNT(*) as total FROM commandes");
    if ($result) $stats['total_commandes'] = $result->fetch_assoc()['total'];
    
    $result = $conn->query("SELECT COUNT(*) as total FROM commandes WHERE status IN ('en cours', 'PENDING', 'EN_COURS')");
    if ($result) $stats['commandes_en_cours'] = $result->fetch_assoc()['total'];
    
    $result = $conn->query("SELECT COUNT(*) as total FROM commandes WHERE status IN ('terminer', 'TERMINER', 'CONFIRMED')");
    if ($result) $stats['commandes_terminees'] = $result->fetch_assoc()['total'];
    
    $result = $conn->query("SELECT COUNT(*) as total FROM commandes WHERE livreur_id IS NULL AND status IN ('en cours', 'PENDING', 'EN_COURS')");
    if ($result) $stats['commandes_sans_livreur'] = $result->fetch_assoc()['total'];
    
    // Statistiques livreurs
    $result = $conn->query("SELECT COUNT(*) as total FROM livreurs WHERE is_active = 1");
    if ($result) $stats['total_livreurs'] = $result->fetch_assoc()['total'];
    
    $result = $conn->query("SELECT COUNT(*) as total FROM livreurs WHERE is_active = 1 AND is_available = 1");
    if ($result) $stats['livreurs_disponibles'] = $result->fetch_assoc()['total'];
    
    // Statistiques villes
    $result = $conn->query("SELECT COUNT(*) as total FROM villes WHERE is_active = 1");
    if ($result) $stats['total_villes'] = $result->fetch_assoc()['total'];
}

// Génération du token CSRF
if (empty($_SESSION['csrf_token'])) {
    $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
}

if (!isset($_SESSION['username'])) {
    $_SESSION['username'] = 'Admin';
}

// 💡 NOUVEAU : Traiter les actions POST des sections AVANT d'envoyer le HTML
// Cela permet aux sections de faire des redirections si nécessaire
$processing_post_only = false;
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $section_file = "sections/{$current_section}.php";
    if (file_exists($section_file)) {
        // Activer le output buffering pour capturer toute sortie accidentelle
        ob_start();
        
        // Variable pour indiquer qu'on traite uniquement le POST (pas d'affichage HTML)
        $processing_post_only = true;
        
        // Inclure la section pour traiter les POST
        // Les redirections dans les sections fonctionneront car aucun HTML n'a été envoyé
        include $section_file;
        
        // Si une redirection a été faite (avec exit), on n'arrive jamais ici
        // Sinon, on nettoie le buffer et on continue
        ob_end_clean();
        
        // Réinitialiser pour l'affichage normal
        $processing_post_only = false;
    }
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Système de Gestion - Soko Fast Admin</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --primary-color: #F2B316;
            --primary-dark: #d99a00;
            --secondary-color: #2c3e50;
            --success-color: #28a745;
            --danger-color: #dc3545;
            --warning-color: #ffc107;
            --info-color: #17a2b8;
            --light-bg: #f8f9fa;
            --dark-text: #2c3e50;
        }

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Roboto', sans-serif;
            background-color: var(--light-bg);
            display: flex;
            min-height: 100vh;
        }

        /* Sidebar */
        .sidebar {
            width: 280px;
            background: linear-gradient(180deg, var(--secondary-color) 0%, #1a252f 100%);
            color: #fff;
            display: flex;
            flex-direction: column;
            box-shadow: 2px 0 10px rgba(0,0,0,0.1);
            position: fixed;
            height: 100vh;
            overflow-y: auto;
        }

        .sidebar-header {
            padding: 25px 20px;
            text-align: center;
            border-bottom: 1px solid rgba(255,255,255,0.1);
            background: rgba(0,0,0,0.2);
        }

        .sidebar-header img {
            width: 80px;
            height: 80px;
            border-radius: 50%;
            border: 3px solid var(--primary-color);
            margin-bottom: 15px;
        }

        .sidebar-header h4 {
            color: var(--primary-color);
            font-weight: 700;
            margin: 0;
        }

        .sidebar-header p {
            color: rgba(255,255,255,0.7);
            font-size: 0.9em;
            margin: 5px 0 0 0;
        }

        .sidebar-menu {
            list-style: none;
            padding: 20px 0;
            flex: 1;
        }

        .sidebar-menu li {
            margin: 5px 0;
        }

        .sidebar-menu a {
            display: flex;
            align-items: center;
            padding: 15px 25px;
            color: rgba(255,255,255,0.8);
            text-decoration: none;
            transition: all 0.3s ease;
            border-left: 3px solid transparent;
        }

        .sidebar-menu a:hover,
        .sidebar-menu a.active {
            background: rgba(255,255,255,0.1);
            color: #fff;
            border-left-color: var(--primary-color);
            padding-left: 22px;
        }

        .sidebar-menu a i {
            width: 25px;
            margin-right: 15px;
            font-size: 1.1em;
        }

        .sidebar-menu .badge {
            margin-left: auto;
            background: var(--danger-color);
            padding: 3px 8px;
            border-radius: 12px;
            font-size: 0.75em;
        }

        /* Main Content */
        .main-content {
            margin-left: 280px;
            flex: 1;
            padding: 30px 40px;
            max-width: calc(100vw - 280px);
            transition: margin-left 0.3s ease, padding 0.3s ease;
        }

        .page-header {
            background: white;
            padding: 20px 25px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.05);
            margin-bottom: 25px;
            margin-top: 10px;
        }

        .page-header h1 {
            color: var(--dark-text);
            font-weight: 700;
            margin: 0;
            font-size: 1.5em;
        }

        .page-header p {
            color: #6c757d;
            margin: 5px 0 0 0;
        }

        /* Stats Cards */
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-bottom: 20px;
        }

        .stat-card {
            background: white;
            padding: 18px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.05);
            transition: transform 0.3s ease, box-shadow 0.3s ease;
        }

        .stat-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 5px 20px rgba(0,0,0,0.1);
        }

        .stat-card .icon {
            width: 50px;
            height: 50px;
            border-radius: 8px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.3em;
            margin-bottom: 12px;
        }

        .stat-card.primary .icon { background: rgba(242, 179, 22, 0.1); color: var(--primary-color); }
        .stat-card.success .icon { background: rgba(40, 167, 69, 0.1); color: var(--success-color); }
        .stat-card.warning .icon { background: rgba(255, 193, 7, 0.1); color: var(--warning-color); }
        .stat-card.info .icon { background: rgba(23, 162, 184, 0.1); color: var(--info-color); }
        .stat-card.danger .icon { background: rgba(220, 53, 69, 0.1); color: var(--danger-color); }

        .stat-card h3 {
            font-size: 1.6em;
            font-weight: 700;
            margin: 0;
            color: var(--dark-text);
        }

        .stat-card p {
            color: #6c757d;
            margin: 3px 0 0 0;
            font-size: 0.85em;
        }

        /* Content Card */
        .content-card {
            background: white;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.05);
            padding: 20px;
            margin-bottom: 20px;
        }

        .content-card h2 {
            color: var(--dark-text);
            font-weight: 600;
            margin-bottom: 15px;
            padding-bottom: 12px;
            border-bottom: 2px solid var(--light-bg);
            font-size: 1.3em;
        }

        /* Tables */
        .table-responsive {
            border-radius: 10px;
            overflow: hidden;
        }

        .table thead {
            background: var(--secondary-color);
            color: white;
        }

        .table thead th {
            border: none;
            padding: 12px 10px;
            font-weight: 600;
            font-size: 0.9em;
        }

        .table tbody tr {
            transition: background 0.2s ease;
        }

        .table tbody tr:hover {
            background: var(--light-bg);
        }

        .table tbody td {
            padding: 12px 10px;
            vertical-align: middle;
            font-size: 0.9em;
        }

        /* Badges */
        .badge {
            padding: 6px 12px;
            border-radius: 20px;
            font-weight: 500;
            font-size: 0.85em;
        }

        .badge-success { background: var(--success-color); color: white; }
        .badge-warning { background: var(--warning-color); color: #000; }
        .badge-danger { background: var(--danger-color); color: white; }
        .badge-info { background: var(--info-color); color: white; }
        .badge-primary { background: var(--primary-color); color: #000; }

        /* Buttons */
        .btn {
            border-radius: 6px;
            padding: 8px 16px;
            font-weight: 500;
            transition: all 0.3s ease;
            font-size: 0.9em;
        }
        
        .btn-sm {
            padding: 6px 12px;
            font-size: 0.85em;
        }

        .btn-primary {
            background: var(--primary-color);
            border: none;
            color: #000;
        }

        .btn-primary:hover {
            background: var(--primary-dark);
            transform: translateY(-2px);
            box-shadow: 0 4px 10px rgba(242, 179, 22, 0.3);
        }

        /* Forms */
        .form-control, .form-select {
            border-radius: 6px;
            border: 1px solid #dee2e6;
            padding: 8px 12px;
            font-size: 0.9em;
        }

        .form-control:focus, .form-select:focus {
            border-color: var(--primary-color);
            box-shadow: 0 0 0 0.2rem rgba(242, 179, 22, 0.25);
        }

        /* Alerts */
        .alert {
            border-radius: 8px;
            border: none;
            padding: 15px 20px;
        }

        /* Section Content (hidden by default) */
        .section-content {
            display: none;
        }

        .section-content.active {
            display: block;
        }

        /* Loading Spinner */
        .spinner-border {
            width: 3rem;
            height: 3rem;
            border-width: 0.3em;
        }

        /* Mobile Menu Toggle */
        .mobile-menu-toggle {
            display: none;
            position: fixed;
            top: 15px;
            left: 15px;
            z-index: 1001;
            background: var(--secondary-color);
            color: white;
            border: none;
            padding: 12px 15px;
            border-radius: 8px;
            font-size: 1.2em;
            cursor: pointer;
            box-shadow: 0 2px 10px rgba(0,0,0,0.2);
        }

        .mobile-menu-toggle:hover {
            background: var(--primary-color);
            color: #000;
        }

        /* Responsive */
        @media (max-width: 1200px) {
            .sidebar {
                width: 260px;
            }
            
            .main-content {
                margin-left: 260px;
                padding: 25px 30px;
                max-width: calc(100vw - 260px);
            }
            
            .stats-grid {
                grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
                gap: 12px;
            }
        }
        
        @media (max-width: 992px) {
            .sidebar {
                transform: translateX(-100%);
                transition: transform 0.3s ease;
                z-index: 1000;
                width: 260px;
            }

            .sidebar.active {
                transform: translateX(0);
            }

            .mobile-menu-toggle {
                display: block;
            }

            .main-content {
                margin-left: 0;
                padding: 70px 20px 20px;
                max-width: 100vw;
            }

            .stats-grid {
                grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
                gap: 12px;
                margin-bottom: 15px;
            }
            
            .stat-card {
                padding: 15px;
            }
            
            .stat-card h3 {
                font-size: 1.4em;
            }

            .page-header {
                padding: 18px 15px;
                margin-bottom: 20px;
                margin-top: 10px;
            }

            .page-header h1 {
                font-size: 1.3em;
            }

            .table {
                font-size: 0.85em;
            }

            .table thead th,
            .table tbody td {
                padding: 8px 6px;
            }
            
            .content-card {
                padding: 15px;
                margin-bottom: 15px;
            }
            
            .content-card h2 {
                font-size: 1.2em;
                margin-bottom: 12px;
            }

            .btn-group {
                display: flex;
                flex-direction: column;
                gap: 5px;
            }

            .btn-group .btn {
                width: 100%;
                margin: 0;
            }
        }

        @media (max-width: 768px) {
            .sidebar {
                width: 200px;
            }
            
            .main-content {
                padding: 60px 12px 12px;
            }
            
            .page-header {
                padding: 15px 12px;
                margin-bottom: 18px;
                margin-top: 8px;
            }
            
            .page-header h1 {
                font-size: 1.2em;
            }

            .content-card {
                padding: 12px;
                margin-bottom: 12px;
            }
            
            .content-card h2 {
                font-size: 1.1em;
                margin-bottom: 10px;
                padding-bottom: 8px;
            }

            .stats-grid {
                grid-template-columns: 1fr;
                gap: 10px;
                margin-bottom: 15px;
            }

            .stat-card {
                padding: 15px;
            }
            
            .stat-card .icon {
                width: 45px;
                height: 45px;
                font-size: 1.2em;
                margin-bottom: 10px;
            }

            .stat-card h3 {
                font-size: 1.3em;
            }
            
            .stat-card p {
                font-size: 0.8em;
            }

            .table {
                font-size: 0.85em;
            }

            .table thead {
                display: none;
            }

            .table tbody tr {
                display: block;
                margin-bottom: 12px;
                border: 1px solid #dee2e6;
                border-radius: 6px;
                padding: 10px;
                background: white;
            }

            .table tbody td {
                display: flex;
                justify-content: space-between;
                padding: 6px 0;
                border: none;
                text-align: right;
                font-size: 0.85em;
            }

            .table tbody td:last-child {
                border-bottom: none;
            }

            .table tbody td::before {
                content: attr(data-label);
                font-weight: 600;
                color: var(--secondary-color);
                margin-right: 10px;
                font-size: 0.85em;
            }

            .modal-dialog {
                margin: 10px;
            }

            .modal-content {
                padding: 15px;
            }
            
            .btn {
                padding: 6px 12px;
                font-size: 0.85em;
            }
            
            .btn-group {
                flex-direction: column;
                width: 100%;
            }
            
            .btn-group .btn {
                margin: 4px 0;
                width: 100%;
            }
        }

        @media (max-width: 576px) {
            .sidebar {
                width: 180px;
            }
            
            .main-content {
                padding: 55px 10px 10px;
            }

            .page-header {
                padding: 12px 10px;
                margin-bottom: 15px;
                margin-top: 5px;
            }

            .page-header h1 {
                font-size: 1.1em;
            }
            
            .page-header p {
                font-size: 0.85em;
            }

            .content-card {
                padding: 10px;
                margin-bottom: 10px;
            }
            
            .content-card h2 {
                font-size: 1em;
                margin-bottom: 8px;
                padding-bottom: 6px;
            }

            .stats-grid {
                gap: 8px;
                margin-bottom: 12px;
            }

            .stat-card {
                padding: 12px;
            }
            
            .stat-card .icon {
                width: 40px;
                height: 40px;
                font-size: 1.1em;
                margin-bottom: 8px;
            }

            .stat-card h3 {
                font-size: 1.2em;
            }
            
            .stat-card p {
                font-size: 0.75em;
            }

            .table tbody tr {
                padding: 8px;
                margin-bottom: 10px;
            }

            .table tbody td {
                padding: 5px 0;
                font-size: 0.8em;
            }

            .btn {
                padding: 6px 10px;
                font-size: 0.8em;
            }
            
            .btn-sm {
                padding: 4px 8px;
                font-size: 0.75em;
            }

            .badge {
                padding: 4px 8px;
                font-size: 0.75em;
            }

            .form-control,
            .form-select {
                padding: 6px 10px;
                font-size: 0.8em;
            }
            
            .mobile-menu-toggle {
                padding: 10px 12px;
                font-size: 1em;
            }
        }
        
        @media (max-width: 400px) {
            .sidebar {
                width: 100%;
            }
            
            .main-content {
                padding: 50px 8px 8px;
            }
            
            .page-header {
                padding: 10px 8px;
                margin-top: 5px;
            }
            
            .content-card {
                padding: 8px;
            }
            
            .stat-card {
                padding: 10px;
            }
        }

        /* Overlay pour mobile */
        .sidebar-overlay {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.5);
            z-index: 999;
        }

        .sidebar-overlay.active {
            display: block;
        }

        @media (min-width: 993px) {
            .sidebar-overlay {
                display: none !important;
            }
        }
        
        /* Optimisation pour très grands écrans */
        @media (min-width: 1400px) {
            .main-content {
                max-width: 1400px;
                margin: 0 auto;
                margin-left: 300px;
                padding: 30px 50px;
            }
        }
        
        /* Amélioration de la lisibilité */
        body {
            font-size: 14px;
            line-height: 1.5;
        }
        
        /* Réduction des espacements généraux */
        * {
            box-sizing: border-box;
        }

        /* Action buttons in tables */
        .btn-sm {
            padding: 5px 12px;
            font-size: 0.85em;
        }

        .btn-group .btn {
            margin: 0 2px;
        }
    </style>
</head>
<body>
    <!-- Mobile Menu Toggle -->
    <button class="mobile-menu-toggle" id="mobileMenuToggle">
        <i class="fas fa-bars"></i>
    </button>

    <!-- Overlay pour fermer le menu mobile -->
    <div class="sidebar-overlay" id="sidebarOverlay"></div>

    <!-- Sidebar -->
    <div class="sidebar" id="sidebar">
        <div class="sidebar-header">
            <img src="logo.png" alt="Logo" onerror="this.src='data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 width=%2280%22 height=%2280%22%3E%3Crect width=%2280%22 height=%2280%22 fill=%22%23F2B316%22/%3E%3Ctext x=%2250%25%22 y=%2250%22 text-anchor=%22middle%22 dy=%22.3em%22 fill=%22%23000%22 font-size=%2220%22 font-weight=%22bold%22%3ESOKO%3C/text%3E%3C/svg%3E'">
            <h4>Système de Gestion</h4>
            <p><?php echo htmlspecialchars($_SESSION['username']); ?></p>
        </div>
        <ul class="sidebar-menu">
            <li>
                <a href="?section=dashboard" class="<?php echo $current_section === 'dashboard' ? 'active' : ''; ?>">
                    <i class="fas fa-tachometer-alt"></i>
                    <span>Tableau de bord</span>
                </a>
            </li>
            <li>
                <a href="?section=commandes" class="<?php echo $current_section === 'commandes' ? 'active' : ''; ?>">
                    <i class="fas fa-shopping-cart"></i>
                    <span>Commandes</span>
                    <?php if ($stats['commandes_en_cours'] > 0): ?>
                        <span class="badge"><?php echo $stats['commandes_en_cours']; ?></span>
                    <?php endif; ?>
                </a>
            </li>
            <li>
                <a href="?section=attribution" class="<?php echo $current_section === 'attribution' ? 'active' : ''; ?>">
                    <i class="fas fa-user-tie"></i>
                    <span>Attribution Livreurs</span>
                    <?php if ($stats['commandes_sans_livreur'] > 0): ?>
                        <span class="badge"><?php echo $stats['commandes_sans_livreur']; ?></span>
                    <?php endif; ?>
                </a>
            </li>
            <li>
                <a href="?section=livreurs" class="<?php echo $current_section === 'livreurs' ? 'active' : ''; ?>">
                    <i class="fas fa-motorcycle"></i>
                    <span>Livreurs</span>
                </a>
            </li>
            <li>
                <a href="?section=villes" class="<?php echo $current_section === 'villes' ? 'active' : ''; ?>">
                    <i class="fas fa-map-marker-alt"></i>
                    <span>Villes</span>
                </a>
            </li>
            <li>
                <a href="?section=commentaires" class="<?php echo $current_section === 'commentaires' ? 'active' : ''; ?>">
                    <i class="fas fa-comments"></i>
                    <span>Commentaires</span>
                </a>
            </li>
            <li>
                <a href="?section=statistiques" class="<?php echo $current_section === 'statistiques' ? 'active' : ''; ?>">
                    <i class="fas fa-chart-bar"></i>
                    <span>Statistiques</span>
                </a>
            </li>
            <li>
                <a href="?section=utilisateurs" class="<?php echo $current_section === 'utilisateurs' ? 'active' : ''; ?>">
                    <i class="fas fa-users"></i>
                    <span>Utilisateurs</span>
                </a>
            </li>
            <li>
                <a href="?section=produits" class="<?php echo $current_section === 'produits' ? 'active' : ''; ?>">
                    <i class="fas fa-box"></i>
                    <span>Produits</span>
                </a>
            </li>
            <li>
                <a href="?section=logs" class="<?php echo $current_section === 'logs' ? 'active' : ''; ?>">
                    <i class="fas fa-exclamation-triangle"></i>
                    <span>Logs & Erreurs</span>
                </a>
            </li>
            <li style="margin-top: auto;">
                <a href="?action=logout">
                    <i class="fas fa-sign-out-alt"></i>
                    <span>Déconnexion</span>
                </a>
            </li>
        </ul>
    </div>

    <!-- Main Content -->
    <div class="main-content">
        <?php
        // Inclusion des sections
        $section_file = "sections/{$current_section}.php";
        if (file_exists($section_file)) {
            include $section_file;
        } else {
            include 'sections/dashboard.php';
        }
        ?>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        // Base URL pour les API
        const API_BASE_URL = window.location.origin + '/soko/backend';
        
        // Gestion du menu mobile
        const mobileMenuToggle = document.getElementById('mobileMenuToggle');
        const sidebar = document.getElementById('sidebar');
        const sidebarOverlay = document.getElementById('sidebarOverlay');
        
        function toggleSidebar() {
            sidebar.classList.toggle('active');
            sidebarOverlay.classList.toggle('active');
        }
        
        if (mobileMenuToggle) {
            mobileMenuToggle.addEventListener('click', toggleSidebar);
        }
        
        if (sidebarOverlay) {
            sidebarOverlay.addEventListener('click', toggleSidebar);
        }
        
        // Fermer le menu lors du clic sur un lien
        const sidebarLinks = document.querySelectorAll('.sidebar-menu a');
        sidebarLinks.forEach(link => {
            link.addEventListener('click', () => {
                if (window.innerWidth <= 992) {
                    toggleSidebar();
                }
            });
        });
        
        // Ajouter les labels pour les tables responsive
        document.addEventListener('DOMContentLoaded', function() {
            const tables = document.querySelectorAll('.table');
            tables.forEach(table => {
                const headers = table.querySelectorAll('thead th');
                const rows = table.querySelectorAll('tbody tr');
                
                rows.forEach(row => {
                    const cells = row.querySelectorAll('td');
                    cells.forEach((cell, index) => {
                        if (headers[index]) {
                            cell.setAttribute('data-label', headers[index].textContent.trim());
                        }
                    });
                });
            });
        });
        
        // Fonctions utilitaires
        function showAlert(message, type = 'success') {
            const alertDiv = document.createElement('div');
            alertDiv.className = `alert alert-${type} alert-dismissible fade show`;
            alertDiv.innerHTML = `
                ${message}
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            `;
            document.querySelector('.main-content').insertBefore(alertDiv, document.querySelector('.main-content').firstChild);
            setTimeout(() => alertDiv.remove(), 5000);
        }

        function formatDate(dateString) {
            const date = new Date(dateString);
            return date.toLocaleDateString('fr-FR', {
                year: 'numeric',
                month: 'long',
                day: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            });
        }

        function formatCurrency(amount) {
            return new Intl.NumberFormat('fr-FR', {
                style: 'currency',
                currency: 'USD'
            }).format(amount);
        }
    </script>
</body>
</html>

