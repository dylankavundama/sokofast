<?php
// dashboard.php - Tableau de bord
?>
<div class="page-header">
    <h1><i class="fas fa-tachometer-alt"></i> Tableau de bord</h1>
    <p>Vue d'ensemble de votre système de gestion</p>
</div>

<!-- Statistiques -->
<div class="stats-grid">
    <div class="stat-card primary">
        <div class="icon">
            <i class="fas fa-shopping-cart"></i>
        </div>
        <h3><?php echo number_format($stats['total_commandes']); ?></h3>
        <p>Total Commandes</p>
    </div>
    
    <div class="stat-card warning">
        <div class="icon">
            <i class="fas fa-clock"></i>
        </div>
        <h3><?php echo number_format($stats['commandes_en_cours']); ?></h3>
        <p>Commandes en cours</p>
    </div>
    
    <div class="stat-card success">
        <div class="icon">
            <i class="fas fa-check-circle"></i>
        </div>
        <h3><?php echo number_format($stats['commandes_terminees']); ?></h3>
        <p>Commandes terminées</p>
    </div>
    
    <div class="stat-card danger">
        <div class="icon">
            <i class="fas fa-exclamation-triangle"></i>
        </div>
        <h3><?php echo number_format($stats['commandes_sans_livreur']); ?></h3>
        <p>Commandes sans livreur</p>
    </div>
    
    <div class="stat-card info">
        <div class="icon">
            <i class="fas fa-motorcycle"></i>
        </div>
        <h3><?php echo number_format($stats['total_livreurs']); ?></h3>
        <p>Total Livreurs</p>
    </div>
    
    <div class="stat-card info">
        <div class="icon">
            <i class="fas fa-user-check"></i>
        </div>
        <h3><?php echo number_format($stats['livreurs_disponibles']); ?></h3>
        <p>Livreurs disponibles</p>
    </div>
    
    <div class="stat-card primary">
        <div class="icon">
            <i class="fas fa-map-marker-alt"></i>
        </div>
        <h3><?php echo number_format($stats['total_villes']); ?></h3>
        <p>Villes actives</p>
    </div>
</div>

<!-- Commandes récentes -->
<div class="content-card">
    <h2><i class="fas fa-list"></i> Commandes récentes</h2>
    <div class="table-responsive">
        <table class="table table-hover">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Client</th>
                    <th>Produit</th>
                    <th>Quantité</th>
                    <th>Montant</th>
                    <th>Statut</th>
                    <th>Date</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                <?php
                $query = "SELECT c.id, c.name, c.product_name, c.quantity, c.total_price, 
                                 c.status, c.order_date, c.livreur_id,
                                 l.nom as livreur_nom, l.prenom as livreur_prenom
                          FROM commandes c
                          LEFT JOIN livreurs l ON c.livreur_id = l.id
                          ORDER BY c.order_date DESC
                          LIMIT 10";
                $result = $conn->query($query);
                
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
                    <td><span class="badge badge-<?php echo $status_class; ?>"><?php echo $status_text; ?></span></td>
                    <td><?php echo date('d/m/Y H:i', strtotime($row['order_date'])); ?></td>
                    <td>
                        <a href="?section=commandes&id=<?php echo $row['id']; ?>" class="btn btn-sm btn-primary">
                            <i class="fas fa-eye"></i> Voir
                        </a>
                    </td>
                </tr>
                <?php
                    endwhile;
                else:
                ?>
                <tr>
                    <td colspan="8" class="text-center text-muted">Aucune commande récente</td>
                </tr>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
</div>

<!-- Actions rapides -->
<div class="content-card">
    <h2><i class="fas fa-bolt"></i> Actions rapides</h2>
    <div class="row">
        <div class="col-md-3 mb-3">
            <a href="?section=attribution" class="btn btn-primary w-100">
                <i class="fas fa-user-tie"></i><br>
                Attribuer des livreurs
            </a>
        </div>
        <div class="col-md-3 mb-3">
            <a href="?section=commandes" class="btn btn-success w-100">
                <i class="fas fa-shopping-cart"></i><br>
                Voir toutes les commandes
            </a>
        </div>
        <div class="col-md-3 mb-3">
            <a href="?section=livreurs" class="btn btn-info w-100">
                <i class="fas fa-motorcycle"></i><br>
                Gérer les livreurs
            </a>
        </div>
        <div class="col-md-3 mb-3">
            <a href="?section=statistiques" class="btn btn-warning w-100">
                <i class="fas fa-chart-bar"></i><br>
                Voir les statistiques
            </a>
        </div>
    </div>
</div>

