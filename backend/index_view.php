<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Gestion des Commandes - Soko Fast Admin</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    <style>
        body {
            font-family: 'Roboto', sans-serif;
            background-color: #f0f2f5; /* Light grey background for the whole page */
            margin: 0;
            display: flex; /* Use flexbox for layout */
            min-height: 100vh; /* Ensure body takes full viewport height */
        }

        /* Sidebar styles */
        .sidebar {
            width: 250px; /* Fixed width for the sidebar */
            background-color: #2c3e50; /* Darker background like the image */
            color: #ecf0f1; /* Light text color */
            padding-top: 20px;
            flex-shrink: 0; /* Prevent sidebar from shrinking */
            display: flex;
            flex-direction: column;
            box-shadow: 2px 0 5px rgba(0,0,0,0.1); /* Subtle shadow */
        }

        .sidebar .sidebar-header {
            text-align: center;
            padding: 10px 0 30px 0;
            border-bottom: 1px solid rgba(255,255,255,0.1);
        }

        .sidebar .profile-info {
            margin-bottom: 20px;
        }

        .sidebar .profile-info img {
            width: 70px; /* Increased size */
            height: 70px; /* Increased size */
            border-radius: 50%;
            object-fit: cover;
            border: 2px solid #007bff; /* Primary color border */
            padding: 1px; /* Small padding to ensure border visibility */
        }

        .sidebar .profile-info h5 {
            color: #fff;
            margin-top: 10px;
            margin-bottom: 5px;
            font-weight: bold;
        }

        .sidebar .profile-info p {
            font-size: 0.85em;
            color: #bdc3c7;
        }

        .sidebar-menu {
            list-style: none;
            padding: 0;
            margin: 0;
            flex-grow: 1; /* Allow menu to take available space */
            display: flex; /* Use flexbox for menu items */
            flex-direction: column; /* Stack menu items vertically */
        }

        .sidebar-menu .nav-item {
            border-bottom: 1px solid rgba(255,255,255,0.05); /* Subtle separator */
        }

        .sidebar-menu .nav-link {
            display: flex;
            align-items: center;
            padding: 15px 25px;
            color: #ecf0f1;
            text-decoration: none;
            transition: background-color 0.2s ease, color 0.2s ease;
        }

        .sidebar-menu .nav-link:hover,
        .sidebar-menu .nav-link.active {
            background-color: #34495e; /* Darker on hover/active */
            color: #fff;
            border-left: 5px solid #007bff; /* Blue border for active link */
            padding-left: 20px; /* Adjust padding due to border */
        }

        .sidebar-menu .nav-link i {
            margin-right: 15px;
            font-size: 1.1em;
            width: 20px; /* Ensure icon alignment */
            text-align: center;
        }

        /* Push logout to the bottom */
        .sidebar-menu .nav-item.mt-auto {
            margin-top: auto !important; /* Force margin-top auto */
            border-top: 1px solid rgba(255,255,255,0.1); /* Add a top separator */
            padding-top: 10px;
        }

        /* Main Content styles */
        .main-content {
            flex-grow: 1; /* Take remaining width */
            padding: 20px;
            overflow-y: auto; /* Enable scrolling for content if needed */
        }

        /* Top Bar for Search/User Info */
        .top-bar {
            background-color: #fff;
            padding: 15px 20px;
            margin-bottom: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.05);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .top-bar .breadcrumb {
            margin-bottom: 0; /* Remove default margin from breadcrumb */
        }

        /* Status Badges */
        .status-badge {
            padding: 5px 10px;
            border-radius: 20px;
            font-size: 13px; /* Slightly smaller font for badges */
            font-weight: 500;
            text-transform: capitalize;
            white-space: nowrap;
            min-width: 90px; /* Ensures consistent width for all badges */
            display: inline-block; /* Allows min-width to work */
            text-align: center;
        }
        .status-terminer {
            background-color: #d4edda; /* Light green */
            color: #155724; /* Dark green */
        }
        .status-en-cours {
            background-color: #fff3cd; /* Light yellow */
            color: #856404; /* Dark yellow */
        }
        .status-annuler {
            background-color: #f8d7da; /* Light red */
            color: #721c24; /* Dark red */
        }
        .status-secondary { /* Fallback for unknown status */
            background-color: #e2e3e5;
            color: #495057;
        }

        /* Table specific styles */
        .table thead.table-dark th {
            font-weight: bold;
        }
        .table tbody tr td {
            vertical-align: middle; /* Align content vertically in table cells */
        }

        /* Responsive adjustments */
        @media (max-width: 768px) {
            .sidebar {
                width: 100%;
                height: auto;
                position: relative;
                box-shadow: none;
                border-bottom: 1px solid rgba(255,255,255,0.1);
                padding-top: 10px; /* Add some padding for mobile */
            }
            body {
                flex-direction: column; /* Stack sidebar and content on small screens */
            }
            .sidebar-header {
                padding-bottom: 15px; /* Adjust padding */
            }
            .sidebar-menu {
                flex-direction: row; /* Make menu items horizontal on small screens */
                flex-wrap: wrap; /* Allow wrapping */
                justify-content: center;
                padding-bottom: 10px;
            }
            .sidebar-menu .nav-item {
                border-bottom: none;
                flex: 1 1 auto; /* Allow items to grow/shrink */
                text-align: center;
                margin: 0 5px; /* Add some horizontal space between items */
            }
            .sidebar-menu .nav-link {
                justify-content: center;
                border-left: none !important; /* Remove active border */
                padding: 10px 5px !important; /* Adjust padding for smaller items */
                flex-direction: column; /* Stack icon and text */
            }
            .sidebar-menu .nav-link i {
                margin-right: 0; /* Remove margin for icons */
                margin-bottom: 5px; /* Add space between icon and text */
                font-size: 1.2em; /* Slightly larger icons */
            }
            .sidebar-menu .nav-link span.badge {
                position: static; /* Reset position for badges */
                margin-left: 0; /* Remove default margin */
            }
            .sidebar .sidebar-menu .nav-item.mt-auto { /* Adjust for mobile, reset forced styles */
                margin-top: 0 !important;
                border-top: none;
                padding-top: 0;
            }
            .top-bar {
                flex-direction: column; /* Stack breadcrumb and user info */
                align-items: flex-start;
                padding: 10px 15px;
            }
            .top-bar .breadcrumb {
                margin-bottom: 10px;
            }
        }
    </style>
</head>
<body>

    <div class="sidebar">
        <div class="sidebar-header">
            <div class="profile-info">
                <img src="./logo.png" alt="Logo Soko Fast" class="mb-2 rounded-circle border border-primary p-1">
                <h5>Soko Fast Admin</h5>
                <p class="text-white-50 small">Bienvenue, <?php echo htmlspecialchars($_SESSION['username']); ?> !</p>
            </div>
        </div>
        <ul class="sidebar-menu">
            <li class="nav-item">
                <a class="nav-link" href="index.php">
                    <i class="fas fa-tachometer-alt"></i> Tableau de bord
                </a>
            </li>
            <li class="nav-item">
                <a class="nav-link active" aria-current="page" href="index.php">
                    <i class="fas fa-clipboard-list"></i> Commandes
                    <?php if ($pending_orders > 0): ?>
                        <span class="badge bg-danger ms-auto rounded-pill"><?php echo $pending_orders; ?></span>
                    <?php endif; ?>
                </a>
            </li>
            <li class="nav-item">
                <a class="nav-link" href="https://babutik.com/wp-admin/edit.php?post_type=product" target="_blank">
                    <i class="fas fa-box"></i> Produits
                </a>
            </li>
            <li class="nav-item">
                <a class="nav-link" href="#">
                    <i class="fas fa-chart-line"></i> Rapports
                </a>
            </li>
            <li class="nav-item">
                <a class="nav-link" href="#">
                    <i class="fas fa-users-cog"></i> Utilisateurs
                </a>
            </li>
            <li class="nav-item mt-auto">
                <a class="nav-link" href="?action=logout">
                    <i class="fas fa-sign-out-alt"></i> Déconnexion
                </a>
            </li>
        </ul>
    </div>

    <div class="main-content">
        <div class="top-bar">
            <nav style="--bs-breadcrumb-divider: '>';" aria-label="breadcrumb">
                <ol class="breadcrumb mb-0">
                    <li class="breadcrumb-item"><a href="index.php">Tableau de bord</a></li>
                    <li class="breadcrumb-item active" aria-current="page">Gestion des Commandes</li>
                </ol>
            </nav>
            <div class="user-info d-flex align-items-center">
                <i class="fas fa-user-circle me-2 fs-5 text-muted"></i>
                <span class="fw-bold">Bonjour, <?php echo htmlspecialchars($_SESSION['username']); ?> !</span>
            </div>
        </div>

        <h1 class="mb-4">Gestion des Commandes</h1>

        <?php if (!empty($message)): ?>
            <div class="alert alert-success alert-dismissible fade show" role="alert">
                <i class="fas fa-check-circle me-2"></i>
                <strong>Succès !</strong> <?php echo $message; ?>
                <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Fermer"></button>
            </div>
        <?php endif; ?>

        <?php if (!empty($error)): ?>
            <div class="alert alert-danger alert-dismissible fade show" role="alert">
                <i class="fas fa-exclamation-triangle me-2"></i>
                <strong>Erreur :</strong> <?php echo $error; ?>
                <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Fermer"></button>
            </div>
        <?php endif; ?>

        <div class="card shadow-sm">
            <div class="card-body">
                <h5 class="card-title mb-3">Liste des Commandes Récentes</h5>
                <div class="table-responsive">
                    <table class="table table-hover table-striped align-middle">
                        <thead class="table-dark">
                            <tr>
                                <th>ID Commande</th>
                                <th>Client</th>
                                <th>Produit(s)</th>
                                <th>Quantité</th>
                                <th>Montant Total</th>
                                <th>Statut</th>
                                <th>Mode de Paiement</th>
                                <th>Date de Commande</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php if ($result && $result->num_rows > 0): ?>
                                <?php while ($row = $result->fetch_assoc()): ?>
                                    <tr>
                                        <td>#<?php echo htmlspecialchars($row['id']); ?></td>
                                        <td><?php echo htmlspecialchars($row['name']); ?></td>
                                        <td><?php echo htmlspecialchars($row['product_name']); ?></td>
                                        <td><?php echo htmlspecialchars($row['quantity']); ?></td>
                                        <td><?php echo number_format($row['total_price'], 2, ',', ' '); ?> $</td>
                                        <td>
                                            <?php
                                            // Mapping des statuts pour l'affichage et les classes CSS
                                            $display_status = '';
                                            $css_status_class = '';
                                            switch ($row['status']) {
                                                case 'en cours':
                                                    $display_status = 'En cours';
                                                    $css_status_class = 'status-en-cours';
                                                    break;
                                                case 'terminer':
                                                    $display_status = 'Terminée';
                                                    $css_status_class = 'status-terminer';
                                                    break;
                                                case 'annuler':
                                                    $display_status = 'Annulée';
                                                    $css_status_class = 'status-annuler';
                                                    break;
                                                default:
                                                    $display_status = 'Inconnu';
                                                    $css_status_class = 'status-secondary'; // Fallback
                                                    break;
                                            }
                                            ?>
                                            <span class="status-badge <?php echo htmlspecialchars($css_status_class); ?>">
                                                <?php echo htmlspecialchars($display_status); ?>
                                            </span>
                                        </td>
                                        <td><?php echo htmlspecialchars($row['payment_method']); ?></td>
                                        <td><?php echo date('d/m/Y H:i', strtotime($row['order_date'])); ?></td>
                                        <td>
                                            <button class="btn btn-sm btn-outline-primary" data-bs-toggle="modal"
                                                data-bs-target="#statusModal"
                                                data-order-id="<?php echo htmlspecialchars($row['id']); ?>"
                                                data-current-status="<?php echo htmlspecialchars($row['status']); ?>">
                                                <i class="fas fa-edit"></i> Modifier
                                            </button>
                                        </td>
                                    </tr>
                                <?php endwhile; ?>
                            <?php else: ?>
                                <tr>
                                    <td colspan="9" class="text-center py-4"> <i class="fas fa-info-circle me-2"></i> Aucune commande n'a été trouvée pour le moment.
                                        <br>
                                        C'est calme par ici ! Revenez plus tard.
                                    </td>
                                </tr>
                            <?php endif; ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <div class="modal fade" id="statusModal" tabindex="-1" aria-labelledby="statusModalLabel" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <form method="POST">
                    <input type="hidden" name="csrf_token" value="<?php echo htmlspecialchars($_SESSION['csrf_token']); ?>">

                    <div class="modal-header">
                        <h5 class="modal-title" id="statusModalLabel">Modifier le statut de la commande <span id="modalOrderDisplayId" class="fw-bold"></span></h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Fermer"></button>
                    </div>
                    <div class="modal-body">
                        <input type="hidden" name="id" id="modalOrderId">
                        <p>Sélectionnez le nouveau statut pour cette commande :</p>
                        <div class="mb-3">
                            <label for="new_status" class="form-label">Nouveau statut :</label>
                            <select class="form-select" id="new_status" name="new_status" required>
                                <option value="en cours">En cours</option>
                                <option value="terminer">Terminée</option>
                                <option value="annuler">Annulée</option>
                            </select>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal"><i class="fas fa-times me-1"></i> Annuler</button>
                        <button type="submit" name="update_status" class="btn btn-primary"><i class="fas fa-save me-1"></i> Enregistrer les modifications</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        // Script pour remplir les données du modal lors de l'ouverture
        const statusModal = document.getElementById('statusModal');
        statusModal.addEventListener('show.bs.modal', function (event) {
            // Bouton qui a déclenché le modal
            const button = event.relatedTarget;
            // Récupérer les informations de la commande via les attributs data-* du bouton
            const orderId = button.getAttribute('data-order-id');
            const currentStatus = button.getAttribute('data-current-status');

            // Mettre à jour les champs du modal
            const modalOrderIdInput = statusModal.querySelector('#modalOrderId');
            const newStatusSelect = statusModal.querySelector('#new_status');
            const modalOrderDisplayId = statusModal.querySelector('#modalOrderDisplayId');

            modalOrderIdInput.value = orderId;
            modalOrderDisplayId.textContent = `#${orderId}`; // Afficher l'ID dans le titre du modal

            // Sélectionner l'option de statut actuelle dans le select
            for (let i = 0; i < newStatusSelect.options.length; i++) {
                if (newStatusSelect.options[i].value === currentStatus) {
                    newStatusSelect.selectedIndex = i;
                    break;
                }
            }
        });
    </script>
</body>
</html>