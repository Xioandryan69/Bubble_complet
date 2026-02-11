<?php
session_start();

if (!isset($_SESSION['loggedin']) || $_SESSION['loggedin'] !== true) {
    header("Location: connexion.php");
    exit();
}

$username = $_SESSION['username'];
$userstatus = $_SESSION['userstatus'];
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Modèle Bubble</title>
</head>
<body>

    <nav>
        <ul>
            <li><a href="#">Accueil</a></li>
            <li><a href="#">Profil</a></li>
            <?php if ($userstatus === 'admin'): ?>
                <li><a href="#">Dashboard</a></li>
            <?php endif; ?>
            <li><a href="#">Déconnexion</a></li>
        </ul>
        <p>Connecté en tant que: <?php echo htmlspecialchars($username); ?> (<?php echo $userstatus; ?>)</p>
    </nav>

    <main>
        <h1>Bienvenue sur Bubble, <?php echo htmlspecialchars($username); ?> !</h1>
        <p>Ceci est un modèle de page avec navbar et footer.</p>
    </main>

    <footer>
        <p>&copy; <?php echo date("Y"); ?> Bubble. Tous droits réservés.</p>
    </footer>

</body>
</html>