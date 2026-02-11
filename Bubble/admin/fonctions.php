<?php
/**
 * Bubble.mg - Fonctions Admin
 * 
 * Fonctions pour la gestion des utilisateurs par l'administrateur :
 * - Lister les utilisateurs en attente
 * - Lister les utilisateurs validés
 * - Détails des services par utilisateur
 */

require_once __DIR__ . '/../core/db.php';

// ============================================================
// Fonctions de listing utilisateurs
// ============================================================

/**
 * Lister tous les utilisateurs en attente de validation
 * 
 * @return array Liste des utilisateurs avec statut 'en_attente'
 */
function listerUtilisateursEnAttente(): array
{
    $pdo = getDB();
    $stmt = $pdo->query("
        SELECT 
            u.id,
            u.username,
            u.email,
            u.full_name,
            u.created_at,
            d.id          AS demande_id,
            d.sous_domaine,
            d.mail        AS demande_mail,
            d.samba       AS demande_samba,
            d.status      AS demande_status,
            d.created_at  AS demande_date
        FROM users u
        LEFT JOIN demandes d ON d.user_id = u.id
        WHERE u.status = 'en_attente'
        ORDER BY u.created_at ASC
    ");
    return $stmt->fetchAll();
}

/**
 * Lister tous les utilisateurs déjà validés par l'admin
 * avec leurs services actifs (mail, samba, DNS)
 * 
 * @return array Liste des utilisateurs validés avec leurs services
 */
function listerUtilisateursValides(): array
{
    $pdo = getDB();
    $stmt = $pdo->query("
        SELECT 
            u.id,
            u.username,
            u.email,
            u.full_name,
            u.ip_address,
            u.created_at,
            u.updated_at,
            vu.email       AS mail_address,
            vu.enabled     AS mail_actif,
            vu.maildir,
            ss.share_name  AS samba_partage,
            ss.share_path  AS samba_chemin,
            ss.enabled     AS samba_actif,
            dr.subdomain   AS dns_sous_domaine,
            dr.fqdn        AS dns_fqdn,
            dr.ip_address  AS dns_ip
        FROM users u
        LEFT JOIN virtual_users vu ON vu.user_id = u.id
        LEFT JOIN samba_shares ss  ON ss.user_id = u.id
        LEFT JOIN dns_records dr   ON dr.user_id = u.id
        WHERE u.status = 'valide'
        ORDER BY u.username ASC
    ");
    return $stmt->fetchAll();
}

// ============================================================
// Fonctions d'affichage HTML
// ============================================================

/**
 * Afficher le tableau HTML des utilisateurs en attente
 */
function afficherUtilisateursEnAttente(): void
{
    $users = listerUtilisateursEnAttente();

    if (empty($users)): ?>
        <div class="alert alert-info">Aucun utilisateur en attente.</div>
    <?php return; endif; ?>

    <h2>Utilisateurs en attente (<?= count($users) ?>)</h2>
    <table class="table">
        <thead>
            <tr>
                <th>ID</th>
                <th>Username</th>
                <th>Email</th>
                <th>Nom complet</th>
                <th>Sous-domaine</th>
                <th>Mail</th>
                <th>Samba</th>
                <th>Date inscription</th>
                <th>Actions</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($users as $user): ?>
            <tr>
                <td><?= htmlspecialchars($user['id']) ?></td>
                <td><?= htmlspecialchars($user['username']) ?></td>
                <td><?= htmlspecialchars($user['email'] ?? '-') ?></td>
                <td><?= htmlspecialchars($user['full_name'] ?? '-') ?></td>
                <td><?= htmlspecialchars($user['sous_domaine'] ?? '-') ?></td>
                <td><?= $user['demande_mail'] ? '✓' : '✗' ?></td>
                <td><?= $user['demande_samba'] ? '✓' : '✗' ?></td>
                <td><?= htmlspecialchars($user['created_at']) ?></td>
                <td>
                    <form method="POST" style="display:inline;">
                        <input type="hidden" name="user_id" value="<?= $user['id'] ?>">
                        <?php if ($user['demande_id']): ?>
                            <input type="hidden" name="demande_id" value="<?= $user['demande_id'] ?>">
                        <?php endif; ?>
                        <button type="submit" name="action" value="accepter" class="btn btn-success btn-sm">Accepter</button>
                        <button type="submit" name="action" value="refuser" class="btn btn-danger btn-sm">Refuser</button>
                    </form>
                </td>
            </tr>
            <?php endforeach; ?>
        </tbody>
    </table>
<?php }

/**
 * Afficher le tableau HTML des utilisateurs validés
 */
function afficherUtilisateursValides(): void
{
    $users = listerUtilisateursValides();

    if (empty($users)): ?>
        <div class="alert alert-info">Aucun utilisateur validé.</div>
    <?php return; endif; ?>

    <h2>Utilisateurs validés (<?= count($users) ?>)</h2>
    <table class="table">
        <thead>
            <tr>
                <th>ID</th>
                <th>Username</th>
                <th>Nom complet</th>
                <th>IP</th>
                <th>DNS (FQDN)</th>
                <th>Mail</th>
                <th>Samba</th>
                <th>Validé le</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($users as $user): ?>
            <tr>
                <td><?= htmlspecialchars($user['id']) ?></td>
                <td><?= htmlspecialchars($user['username']) ?></td>
                <td><?= htmlspecialchars($user['full_name'] ?? '-') ?></td>
                <td><?= htmlspecialchars($user['ip_address'] ?? '-') ?></td>
                <td><?= htmlspecialchars($user['dns_fqdn'] ?? '-') ?></td>
                <td><?= $user['mail_actif'] ? '✓ ' . htmlspecialchars($user['mail_address']) : '✗' ?></td>
                <td><?= $user['samba_actif'] ? '✓ ' . htmlspecialchars($user['samba_chemin']) : '✗' ?></td>
                <td><?= htmlspecialchars($user['updated_at']) ?></td>
            </tr>
            <?php endforeach; ?>
        </tbody>
    </table>
<?php } ?>
