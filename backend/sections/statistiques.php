<?php
// statistiques.php - Statistiques détaillées

// Statistiques générales
$stats_query = "SELECT 
    COUNT(DISTINCT c.id) as total_commandes,
    SUM(CASE WHEN c.status IN ('terminer', 'TERMINER', 'CONFIRMED') THEN 1 ELSE 0 END) as terminees,
    SUM(CASE WHEN c.status IN ('en cours', 'PENDING', 'EN_COURS') THEN 1 ELSE 0 END) as en_cours,
    SUM(c.total_price) as chiffre_affaires,
    COUNT(DISTINCT c.livreur_id) as livreurs_actifs,
    COUNT(DISTINCT c.ville_id) as villes_actives
FROM commandes c";
$stats_result = $conn->query($stats_query);
$stats_data = $stats_result->fetch_assoc();

// Top livreurs
$top_livreurs = $conn->query("SELECT l.nom, l.prenom, COUNT(c.id) as nb_commandes,
                                      SUM(CASE WHEN c.status IN ('terminer', 'TERMINER', 'CONFIRMED') THEN 1 ELSE 0 END) as terminees
                               FROM livreurs l
                               LEFT JOIN commandes c ON l.id = c.livreur_id
                               WHERE l.is_active = 1
                               GROUP BY l.id
                               ORDER BY nb_commandes DESC
                               LIMIT 10");

// Top villes
$top_villes = $conn->query("SELECT v.nom, COUNT(c.id) as nb_commandes,
                                   SUM(c.total_price) as chiffre_affaires
                            FROM villes v
                            LEFT JOIN commandes c ON v.id = c.ville_id
                            WHERE v.is_active = 1
                            GROUP BY v.id
                            ORDER BY nb_commandes DESC
                            LIMIT 10");

// Commandes par mois
$commandes_mois = $conn->query("SELECT DATE_FORMAT(order_date, '%Y-%m') as mois,
                                       COUNT(*) as nb_commandes,
                                       SUM(total_price) as chiffre_affaires
                                FROM commandes
                                WHERE order_date >= DATE_SUB(NOW(), INTERVAL 6 MONTH)
                                GROUP BY mois
                                ORDER BY mois ASC");
?>
<div class="page-header">
    <h1><i class="fas fa-chart-bar"></i> Statistiques</h1>
    <p>Analysez les performances de votre système</p>
</div>

<!-- Statistiques générales -->
<div class="stats-grid">
    <div class="stat-card primary">
        <div class="icon">
            <i class="fas fa-shopping-cart"></i>
        </div>
        <h3><?php echo number_format($stats_data['total_commandes']); ?></h3>
        <p>Total Commandes</p>
    </div>
    
    <div class="stat-card success">
        <div class="icon">
            <i class="fas fa-check-circle"></i>
        </div>
        <h3><?php echo number_format($stats_data['terminees']); ?></h3>
        <p>Commandes terminées</p>
    </div>
    
    <div class="stat-card warning">
        <div class="icon">
            <i class="fas fa-clock"></i>
        </div>
        <h3><?php echo number_format($stats_data['en_cours']); ?></h3>
        <p>Commandes en cours</p>
    </div>
    
    <div class="stat-card info">
        <div class="icon">
            <i class="fas fa-dollar-sign"></i>
        </div>
        <h3><?php echo number_format($stats_data['chiffre_affaires'], 2); ?> $</h3>
        <p>Chiffre d'affaires</p>
    </div>
</div>

<!-- Top Livreurs -->
<div class="content-card">
    <h2><i class="fas fa-trophy"></i> Top 10 Livreurs</h2>
    <div class="table-responsive">
        <table class="table table-hover">
            <thead>
                <tr>
                    <th>Rang</th>
                    <th>Livreur</th>
                    <th>Total commandes</th>
                    <th>Commandes terminées</th>
                    <th>Taux de réussite</th>
                </tr>
            </thead>
            <tbody>
                <?php
                $rang = 1;
                if ($top_livreurs && $top_livreurs->num_rows > 0):
                    while ($row = $top_livreurs->fetch_assoc()):
                        $taux = $row['nb_commandes'] > 0 ? ($row['terminees'] / $row['nb_commandes'] * 100) : 0;
                ?>
                <tr>
                    <td>
                        <?php if ($rang <= 3): ?>
                            <span class="badge badge-<?php echo $rang == 1 ? 'warning' : ($rang == 2 ? 'secondary' : 'info'); ?>">
                                <?php echo $rang; ?><?php echo $rang == 1 ? 'er' : 'ème'; ?>
                            </span>
                        <?php else: ?>
                            #<?php echo $rang; ?>
                        <?php endif; ?>
                    </td>
                    <td><strong><?php echo htmlspecialchars($row['nom'] . ' ' . $row['prenom']); ?></strong></td>
                    <td><?php echo $row['nb_commandes']; ?></td>
                    <td><?php echo $row['terminees']; ?></td>
                    <td>
                        <div class="progress" style="height: 20px;">
                            <div class="progress-bar bg-success" role="progressbar" style="width: <?php echo $taux; ?>%">
                                <?php echo number_format($taux, 1); ?>%
                            </div>
                        </div>
                    </td>
                </tr>
                <?php
                        $rang++;
                    endwhile;
                endif;
                ?>
            </tbody>
        </table>
    </div>
</div>

<!-- Top Villes -->
<div class="content-card">
    <h2><i class="fas fa-map-marked-alt"></i> Top 10 Villes</h2>
    <div class="table-responsive">
        <table class="table table-hover">
            <thead>
                <tr>
                    <th>Rang</th>
                    <th>Ville</th>
                    <th>Nombre de commandes</th>
                    <th>Chiffre d'affaires</th>
                </tr>
            </thead>
            <tbody>
                <?php
                $rang = 1;
                if ($top_villes && $top_villes->num_rows > 0):
                    while ($row = $top_villes->fetch_assoc()):
                ?>
                <tr>
                    <td>#<?php echo $rang; ?></td>
                    <td><strong><?php echo htmlspecialchars($row['nom']); ?></strong></td>
                    <td><?php echo $row['nb_commandes']; ?></td>
                    <td><strong><?php echo number_format($row['chiffre_affaires'], 2); ?> $</strong></td>
                </tr>
                <?php
                        $rang++;
                    endwhile;
                endif;
                ?>
            </tbody>
        </table>
    </div>
</div>

<!-- Évolution mensuelle -->
<div class="content-card">
    <h2><i class="fas fa-chart-line"></i> Évolution des 6 derniers mois</h2>
    <div class="table-responsive">
        <table class="table table-hover">
            <thead>
                <tr>
                    <th>Mois</th>
                    <th>Nombre de commandes</th>
                    <th>Chiffre d'affaires</th>
                </tr>
            </thead>
            <tbody>
                <?php
                if ($commandes_mois && $commandes_mois->num_rows > 0):
                    while ($row = $commandes_mois->fetch_assoc()):
                        $date = DateTime::createFromFormat('Y-m', $row['mois']);
                ?>
                <tr>
                    <td><strong><?php echo $date->format('F Y'); ?></strong></td>
                    <td><?php echo $row['nb_commandes']; ?></td>
                    <td><strong><?php echo number_format($row['chiffre_affaires'], 2); ?> $</strong></td>
                </tr>
                <?php
                    endwhile;
                endif;
                ?>
            </tbody>
        </table>
    </div>
</div>

