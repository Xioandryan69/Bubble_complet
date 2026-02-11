<?php
/**
 * Bubble.mg - Page de connexion
 * Utilise PostgreSQL via core/db.php
 */

session_start();
require_once __DIR__ . '/../core/db.php';

$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = trim($_POST['name'] ?? '');
    $password = $_POST['motdepasse'] ?? '';

    // Authentifier via la fonction du core
    $user = authenticateUser($username, $password);

    if ($user) {
        $_SESSION['user'] = $user;  // Stocker l'utilisateur complet
        $_SESSION['loggedin'] = true;
        $_SESSION['username'] = $user['username'];
        $_SESSION['userstatus'] = $user['status'];  // 'en_attente', 'valide', etc.
        $_SESSION['is_admin'] = $user['is_admin'];

        // Redirection selon le statut
        if ($user['is_admin']) {
            header('Location: ../admin/admin.php');
        } else {
            header('Location: modele.php');
        }
        exit;
    } else {
        $error = 'Nom d\'utilisateur ou mot de passe incorrect.';
    }
}
?>

<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Connexion à Bubble</title>
</head>
<body>
    <h1>Connexion</h1>
    <?php if ($error): ?>
        <p style="color: red;"><?php echo htmlspecialchars($error); ?></p>
    <?php endif; ?>
    <form action="connexion.php" method="post">
        <label for="name">Nom d'utilisateur:</label>
        <input type="text" id="name" name="name" required><br>
        <label for="motdepasse">Mot de passe:</label>
        <input type="password" id="motdepasse" name="motdepasse" required><br>
        <button type="submit">Se connecter</button>
    </form>
    <p>Pas de compte ? <a href="inscription.php">S'inscrire</a></p>
</body>
</html>