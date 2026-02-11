<?php
/**
 * Bubble.mg - Interface Mail (Webmail)
 * 
 * Permet aux utilisateurs de consulter leur boîte mail via IMAP.
 * Nécessite une connexion utilisateur.
 */

session_start();
require_once __DIR__ . '/../core/auth.php'; // Assumer que auth.php gère la vérification de session

// Vérifier que l'utilisateur est connecté
if (!isset($_SESSION['user'])) {
    header('Location: connexion.php');
    exit;
}

$user = $_SESSION['user'];
$username = $user['username'];
$email = $username . '@bubble.mg';

// Configuration IMAP (Dovecot local)
$imap_server = '{localhost:143/imap}INBOX';
$password = $user['password']; // Assumer que le mot de passe est stocké en session ou récupéré

// Connexion IMAP
$imap = imap_open($imap_server, $email, $password);
if (!$imap) {
    die('Erreur de connexion IMAP: ' . imap_last_error());
}

// Récupérer la liste des messages
$num_messages = imap_num_msg($imap);
$messages = [];
for ($i = 1; $i <= $num_messages; $i++) {
    $header = imap_headerinfo($imap, $i);
    $structure = imap_fetchstructure($imap, $i);
    $body = imap_fetchbody($imap, $i, 1); // Corps en texte brut

    $messages[] = [
        'id' => $i,
        'subject' => $header->subject ?? 'Sans sujet',
        'from' => $header->from[0]->mailbox . '@' . $header->from[0]->host,
        'to' => $header->to[0]->mailbox . '@' . $header->to[0]->host,
        'date' => date('d/m/Y H:i:s', strtotime($header->date)),
        'seen' => ($header->Unseen == 'U') ? false : true,
        'body' => $body,
    ];
}

// Fermer la connexion IMAP
imap_close($imap);

// Afficher l'interface
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Boîte Mail - Bubble.mg</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .message-list { list-style: none; padding: 0; }
        .message-item { padding: 10px; border-bottom: 1px solid #ccc; cursor: pointer; }
        .message-item.unread { font-weight: bold; }
        .message-details { margin-top: 20px; padding: 10px; border: 1px solid #ddd; }
        .hidden { display: none; }
    </style>
</head>
<body>
    <h1>Boîte Mail - <?= htmlspecialchars($email) ?></h1>
    <a href="index.php">← Retour à l'accueil</a>

    <h2>Messages (<?= $num_messages ?>)</h2>
    <ul class="message-list">
        <?php foreach ($messages as $msg): ?>
            <li class="message-item <?= $msg['seen'] ? '' : 'unread' ?>" onclick="showMessage(<?= $msg['id'] ?>)">
                <strong>Sujet:</strong> <?= htmlspecialchars($msg['subject']) ?><br>
                <strong>De:</strong> <?= htmlspecialchars($msg['from']) ?><br>
                <strong>Date:</strong> <?= htmlspecialchars($msg['date']) ?>
            </li>
        <?php endforeach; ?>
    </ul>

    <div id="message-details" class="message-details hidden">
        <h3>Détails du Message</h3>
        <p><strong>IP Serveur:</strong> bubble.mg</p>
        <p><strong>Date:</strong> <span id="msg-date"></span></p>
        <p><strong>À:</strong> <span id="msg-to"></span></p>
        <p><strong>De:</strong> <span id="msg-from"></span></p>
        <p><strong>Sujet:</strong> <span id="msg-subject"></span></p>
        <p><strong>Contenu:</strong></p>
        <pre id="msg-body"></pre>
    </div>

    <script>
        const messages = <?= json_encode($messages) ?>;

        function showMessage(id) {
            const msg = messages.find(m => m.id === id);
            if (msg) {
                document.getElementById('msg-date').textContent = msg.date;
                document.getElementById('msg-to').textContent = msg.to;
                document.getElementById('msg-from').textContent = msg.from;
                document.getElementById('msg-subject').textContent = msg.subject;
                document.getElementById('msg-body').textContent = msg.body;
                document.getElementById('message-details').classList.remove('hidden');
            }
        }
    </script>
</body>
</html>