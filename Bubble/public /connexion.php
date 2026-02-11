<?php
session_start();

$host = 'localhost';
$dbname = 'bubble';
$user = 'root';
$pass = '';
$dsn = "mysql:host=$host;dbname=$dbname;charset=utf8mb4";

try {
    $pdo = new PDO($dsn, $user, $pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    die("Erreur de connexion : " . $e->getMessage());
}

$error = '';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $username = $_POST['name'] ?? '';
    $password = $_POST['motdepasse'] ?? '';

    $stmt = $pdo->prepare("SELECT * FROM utilisateur WHERE username = :username AND pwd = :pwd");
    $stmt->execute([
        'username' => $username,
        'pwd' => $password
    ]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($user) {
        $_SESSION['loggedin'] = true;
        $_SESSION['username'] = $user['username'];
        $_SESSION['userstatus'] = $user['userstatus'];
        header("Location: modele.php");
        exit();
    } else {
        $error = 'Nom d\'utilisateur ou mot de passe incorrect.';
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Connexion à Bubble</title>
</head>
<body>
    <h1>Connexion</h1>
    <?php if ($error): ?>
        <p style="color: red;"><?php echo $error; ?></p>
    <?php endif; ?>
    <form action="connexion.php" method="post">
        <label for="name">Nom d'utilisateur:</label>
        <input type="text" id="name" name="name" required><br>
        <label for="motdepasse">Mot de passe:</label>
        <input type="password" id="motdepasse" name="motdepasse" required><br>
        <button type="submit">Se connecter</button>
    </form>
</body>
</html>