<?php
// commentaires.php - Gestion des commentaires

// Récupération des commentaires
$query = "SELECT c.*, 
                 (SELECT COUNT(*) FROM comments WHERE product_id = c.product_id) as total_commentaires
          FROM comments c
          ORDER BY c.created_at DESC
          LIMIT 100";
$result = $conn->query($query);
?>
<div class="page-header">
    <h1><i class="fas fa-comments"></i> Gestion des Commentaires</h1>
    <p>Gérez les commentaires et avis des clients</p>
</div>

<div class="content-card">
    <div class="table-responsive">
        <table class="table table-hover">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Produit ID</th>
                    <th>Utilisateur</th>
                    <th>Commentaire</th>
                    <th>Note</th>
                    <th>Date</th>
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
                    <td><?php echo $row['product_id']; ?></td>
                    <td><strong><?php echo htmlspecialchars($row['user_name']); ?></strong></td>
                    <td>
                        <div style="max-width: 400px;">
                            <?php echo htmlspecialchars(substr($row['comment'], 0, 100)); ?>
                            <?php if (strlen($row['comment']) > 100): ?>...<?php endif; ?>
                        </div>
                    </td>
                    <td>
                        <?php for ($i = 1; $i <= 5; $i++): ?>
                            <i class="fas fa-star <?php echo $i <= $row['rating'] ? 'text-warning' : 'text-muted'; ?>"></i>
                        <?php endfor; ?>
                        <span class="badge badge-primary"><?php echo $row['rating']; ?>/5</span>
                    </td>
                    <td><?php echo date('d/m/Y H:i', strtotime($row['created_at'])); ?></td>
                    <td>
                        <button type="button" class="btn btn-sm btn-primary" data-bs-toggle="modal" data-bs-target="#modalCommentaire<?php echo $row['id']; ?>">
                            <i class="fas fa-eye"></i> Voir
                        </button>
                    </td>
                </tr>

                <!-- Modal Détails Commentaire -->
                <div class="modal fade" id="modalCommentaire<?php echo $row['id']; ?>" tabindex="-1">
                    <div class="modal-dialog">
                        <div class="modal-content">
                            <div class="modal-header">
                                <h5 class="modal-title">Commentaire #<?php echo $row['id']; ?></h5>
                                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                            </div>
                            <div class="modal-body">
                                <p><strong>Produit ID:</strong> <?php echo $row['product_id']; ?></p>
                                <p><strong>Utilisateur:</strong> <?php echo htmlspecialchars($row['user_name']); ?></p>
                                <p><strong>Note:</strong> 
                                    <?php for ($i = 1; $i <= 5; $i++): ?>
                                        <i class="fas fa-star <?php echo $i <= $row['rating'] ? 'text-warning' : 'text-muted'; ?>"></i>
                                    <?php endfor; ?>
                                    (<?php echo $row['rating']; ?>/5)
                                </p>
                                <p><strong>Commentaire:</strong></p>
                                <p><?php echo nl2br(htmlspecialchars($row['comment'])); ?></p>
                                <p><strong>Date:</strong> <?php echo date('d/m/Y à H:i', strtotime($row['created_at'])); ?></p>
                            </div>
                        </div>
                    </div>
                </div>
                <?php
                    endwhile;
                else:
                ?>
                <tr>
                    <td colspan="7" class="text-center text-muted">Aucun commentaire trouvé</td>
                </tr>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
</div>

