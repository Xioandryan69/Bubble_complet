<?php
/**
 * Bubble.mg - Page d'inscription
 * Permet aux utilisateurs de s'inscrire et de soumettre une demande de services.
 * Utilise les scripts existants via les fonctions de core/db.php.
 */

session_start();
require_once __DIR__ . '/../core/db.php';

$error = '';
$success = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = trim($_POST['username'] ?? '');
    $password = $_POST['password'] ?? '';
    $email = trim($_POST['email'] ?? '');
    $fullName = trim($_POST['full_name'] ?? '');
    $sousDomaine = trim($_POST['sous_domaine'] ?? '');
    $mail = isset($_POST['mail']);
    $samba = isset($_POST['samba']);

    // Validation basique
    if (empty($username) || empty($password) || empty($email) || empty($sousDomaine)) {
        $error = 'Tous les champs obligatoires doivent être remplis.';
    } elseif (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        $error = 'Adresse email invalide.';
    } elseif (strlen($password) < 6) {
        $error = 'Le mot de passe doit contenir au moins 6 caractères.';
    } else {
        try {
            // Créer l'utilisateur
            $userId = createUser($username, $password, $email, $fullName);

            // Créer la demande
            $demandeId = createDemande($userId, $sousDomaine, $mail, $samba);

            $success = 'Inscription réussie ! Votre compte est en attente de validation par l\'administrateur.';
        } catch (Exception $e) {
            $error = 'Erreur lors de l\'inscription : ' . $e->getMessage();
        }
    }
}
?>

<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Inscription à Bubble</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        form { max-width: 400px; margin: auto; }
        label { display: block; margin-top: 10px; }
        input, button { width: 100%; padding: 8px; margin-top: 5px; }
        .checkbox { width: auto; }
        .error { color: red; }
        .success { color: green; }
    </style>
</head>
<body>
    <h1>Inscription à Bubble.mg</h1>
    <p>Créez votre compte et demandez vos services.</p>

    <?php if ($error): ?>
        <p class="error"><?php echo htmlspecialchars($error); ?></p>
    <?php endif; ?>
    <?php if ($success): ?>
        <p class="success"><?php echo htmlspecialchars($success); ?></p>
        <a href="connexion.php">Se connecter</a>
    <?php else: ?>
        <form action="inscription.php" method="post">
            <label for="username">Nom d'utilisateur *:</label>
            <input type="text" id="username" name="username" required>

            <label for="password">Mot de passe *:</label>
            <input type="password" id="password" name="password" required>

            <label for="email">Email *:</label>
            <input type="email" id="email" name="email" required>

            <label for="full_name">Nom complet :</label>
            <input type="text" id="full_name" name="full_name">

            <label for="sous_domaine">Sous-domaine souhaité * (ex: monnom) :</label>
            <input type="text" id="sous_domaine" name="sous_domaine" required>
            <small>Devient : monsousdomaine.bubble.mg</small>

            <label>
                <input type="checkbox" name="mail" class="checkbox"> Demander un accès mail (username@bubble.mg)
            </label>

            <label>
                <input type="checkbox" name="samba" class="checkbox"> Demander un partage Samba
            </label>

            <button type="submit">S'inscrire</button>
        </form>
        <p>Déjà inscrit ? <a href="connexion.php">Se connecter</a></p>
    <?php endif; ?>
</body>
</html>