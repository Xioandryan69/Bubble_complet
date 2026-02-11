<?php
/**
 * Bubble.mg - Interface Administrateur
 * 
 * Permet de :
 * - Voir les utilisateurs en attente de validation
 * - Voir les utilisateurs déjà validés
 * - Accepter ou refuser les demandes
 */

session_start();
require_once __DIR__ . '/fonctions.php';

// ── Vérifier que l'admin est connecté ──────────────────────
// TODO: décommenter quand l'auth sera en place
// if (!isset($_SESSION['user']) || !$_SESSION['user']['is_admin']) {
//     header('Location: /public/connexion.php');
//     exit;
// }

// ── Traitement des actions (accepter / refuser) ────────────
$message = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'])) {
    $userId    = (int) ($_POST['user_id'] ?? 0);
    $demandeId = (int) ($_POST['demande_id'] ?? 0);
    $adminId   = (int) ($_SESSION['user']['id'] ?? 1); // 1 = admin par défaut

    if ($_POST['action'] === 'accepter' && $userId > 0) {
        // Valider l'utilisateur
        $ip = $_POST['ip_address'] ?? '10.228.55.' . rand(10, 250);
        validateUser($userId, $ip);
        
        // Accepter la demande si elle existe
        if ($demandeId > 0) {
            acceptDemande($demandeId, $adminId);
        }
        $message = "✓ Utilisateur #$userId accepté avec l'IP $ip";

    } elseif ($_POST['action'] === 'refuser' && $demandeId > 0) {
        rejectDemande($demandeId, $adminId);
        $message = "✗ Demande #$demandeId refusée";
    }
}

// ── Onglet actif ───────────────────────────────────────────
$onglet = $_GET['tab'] ?? 'attente';
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin - Bubble.mg</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, sans-serif; background: #f4f6f9; color: #333; }
        
        .header {
            background: #2c3e50; color: white; padding: 15px 30px;
            display: flex; justify-content: space-between; align-items: center;
        }
        .header h1 { font-size: 1.4em; }
        .header a { color: #ecf0f1; text-decoration: none; }

        .container { max-width: 1200px; margin: 20px auto; padding: 0 20px; }

        .alert {
            padding: 12px 20px; border-radius: 6px; margin-bottom: 20px;
            font-weight: 500;
        }
        .alert-info { background: #d1ecf1; color: #0c5460; border: 1px solid #bee5eb; }
        .alert-success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .alert-danger { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }

        .tabs {
            display: flex; gap: 0; margin-bottom: 20px;
            border-bottom: 2px solid #dee2e6;
        }
        .tabs a {
            padding: 12px 24px; text-decoration: none; color: #6c757d;
            border-bottom: 3px solid transparent; font-weight: 500;
            transition: all 0.2s;
        }
        .tabs a:hover { color: #2c3e50; }
        .tabs a.active {
            color: #2c3e50; border-bottom-color: #3498db;
        }

        .badge {
            background: #e74c3c; color: white; border-radius: 50%;
            padding: 2px 8px; font-size: 0.75em; margin-left: 6px;
        }
        .badge-success { background: #27ae60; }

        .table {
            width: 100%; border-collapse: collapse; background: white;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1); border-radius: 8px;
            overflow: hidden;
        }
        .table th {
            background: #34495e; color: white; padding: 12px 15px;
            text-align: left; font-weight: 500; font-size: 0.9em;
        }
        .table td {
            padding: 10px 15px; border-bottom: 1px solid #eee; font-size: 0.9em;
        }
        .table tbody tr:hover { background: #f8f9fa; }

        .btn {
            padding: 6px 14px; border: none; border-radius: 4px;
            cursor: pointer; font-size: 0.85em; font-weight: 500;
            transition: opacity 0.2s;
        }
        .btn:hover { opacity: 0.85; }
        .btn-success { background: #27ae60; color: white; }
        .btn-danger { background: #e74c3c; color: white; }
        .btn-sm { padding: 4px 10px; font-size: 0.8em; }

        h2 { margin-bottom: 15px; color: #2c3e50; }
    </style>
</head>
<body>

<div class="header">
    <h1>🫧 Bubble.mg — Administration</h1>
    <a href="/public/index.php">← Retour au site</a>
</div>

<div class="container">

    <?php if ($message): ?>
        <div class="alert <?= str_starts_with($message, '✓') ? 'alert-success' : 'alert-danger' ?>">
            <?= htmlspecialchars($message) ?>
        </div>
    <?php endif; ?>

    <?php
        $nbAttente = count(listerUtilisateursEnAttente());
        $nbValides = count(listerUtilisateursValides());
    ?>

    <div class="tabs">
        <a href="?tab=attente" class="<?= $onglet === 'attente' ? 'active' : '' ?>">
            En attente <span class="badge"><?= $nbAttente ?></span>
        </a>
        <a href="?tab=valides" class="<?= $onglet === 'valides' ? 'active' : '' ?>">
            Validés <span class="badge badge-success"><?= $nbValides ?></span>
        </a>
    </div>

    <?php if ($onglet === 'attente'): ?>
        <?php afficherUtilisateursEnAttente(); ?>
    <?php else: ?>
        <?php afficherUtilisateursValides(); ?>
    <?php endif; ?>

</div>

</body>
</html>
