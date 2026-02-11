<?php
/**
 * Bubble.mg - Connexion à la base de données PostgreSQL
 * 
 * Usage:
 *   require_once __DIR__ . '/../core/db.php';
 *   $pdo = getDB();
 */

// ── Configuration ──────────────────────────────────────────
define('DB_HOST', '127.0.0.1');
define('DB_PORT', '5432');
define('DB_NAME', 'bubble');
define('DB_USER', 'bubble_user');
define('DB_PASS', 'bubble_secret_2026');

/**
 * Retourne une instance PDO connectée à PostgreSQL
 * @return PDO
 */
function getDB(): PDO
{
    static $pdo = null;

    if ($pdo === null) {
        $dsn = sprintf(
            'pgsql:host=%s;port=%s;dbname=%s',
            DB_HOST,
            DB_PORT,
            DB_NAME
        );

        try {
            $pdo = new PDO($dsn, DB_USER, DB_PASS, [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES   => false,
            ]);
        } catch (PDOException $e) {
            error_log("Erreur connexion DB: " . $e->getMessage());
            die("Erreur de connexion à la base de données.");
        }
    }

    return $pdo;
}

// ============================================================
// Fonctions CRUD pour les utilisateurs
// ============================================================

/**
 * Créer un nouvel utilisateur (inscription)
 */
function createUser(string $username, string $password, string $email, string $fullName = ''): int
{
    $pdo = getDB();
    $hash = password_hash($password, PASSWORD_BCRYPT);
    
    $stmt = $pdo->prepare("
        INSERT INTO users (username, password_hash, email, full_name, status)
        VALUES (:username, :password_hash, :email, :full_name, 'en_attente')
        RETURNING id
    ");
    $stmt->execute([
        ':username'      => $username,
        ':password_hash' => $hash,
        ':email'         => $email,
        ':full_name'     => $fullName,
    ]);

    return (int) $stmt->fetchColumn();
}

/**
 * Authentifier un utilisateur
 */
function authenticateUser(string $username, string $password): ?array
{
    $pdo = getDB();
    $stmt = $pdo->prepare("SELECT * FROM users WHERE username = :username");
    $stmt->execute([':username' => $username]);
    $user = $stmt->fetch();

    if ($user && password_verify($password, $user['password_hash'])) {
        return $user;
    }
    return null;
}

/**
 * Obtenir un utilisateur par ID
 */
function getUserById(int $id): ?array
{
    $pdo = getDB();
    $stmt = $pdo->prepare("SELECT * FROM users WHERE id = :id");
    $stmt->execute([':id' => $id]);
    return $stmt->fetch() ?: null;
}

/**
 * Lister les utilisateurs par statut
 */
function getUsersByStatus(string $status): array
{
    $pdo = getDB();
    $stmt = $pdo->prepare("SELECT * FROM users WHERE status = :status ORDER BY created_at DESC");
    $stmt->execute([':status' => $status]);
    return $stmt->fetchAll();
}

/**
 * Valider un utilisateur (admin)
 */
function validateUser(int $userId, string $ipAddress): bool
{
    $pdo = getDB();
    $stmt = $pdo->prepare("
        UPDATE users 
        SET status = 'valide', ip_address = :ip, updated_at = NOW()
        WHERE id = :id
    ");
    return $stmt->execute([':id' => $userId, ':ip' => $ipAddress]);
}

// ============================================================
// Fonctions CRUD pour les demandes
// ============================================================

/**
 * Créer une nouvelle demande
 */
function createDemande(int $userId, string $sousDomaine, bool $mail, bool $samba): int
{
    $pdo = getDB();
    $stmt = $pdo->prepare("
        INSERT INTO demandes (user_id, sous_domaine, mail, samba)
        VALUES (:user_id, :sous_domaine, :mail, :samba)
        RETURNING id
    ");
    $stmt->execute([
        ':user_id'      => $userId,
        ':sous_domaine'  => $sousDomaine,
        ':mail'          => $mail ? 'true' : 'false',
        ':samba'         => $samba ? 'true' : 'false',
    ]);

    return (int) $stmt->fetchColumn();
}

/**
 * Lister les demandes en attente (vue admin)
 */
function getPendingDemandes(): array
{
    $pdo = getDB();
    $stmt = $pdo->query("SELECT * FROM v_demandes_pending");
    return $stmt->fetchAll();
}

/**
 * Accepter une demande (admin)
 */
function acceptDemande(int $demandeId, int $adminId): bool
{
    $pdo = getDB();
    $stmt = $pdo->prepare("
        UPDATE demandes 
        SET status = 'accepted', reviewed_by = :admin_id, reviewed_at = NOW(), updated_at = NOW()
        WHERE id = :id AND status = 'pending'
    ");
    return $stmt->execute([':id' => $demandeId, ':admin_id' => $adminId]);
}

/**
 * Refuser une demande (admin)
 */
function rejectDemande(int $demandeId, int $adminId): bool
{
    $pdo = getDB();
    $stmt = $pdo->prepare("
        UPDATE demandes 
        SET status = 'rejected', reviewed_by = :admin_id, reviewed_at = NOW(), updated_at = NOW()
        WHERE id = :id AND status = 'pending'
    ");
    return $stmt->execute([':id' => $demandeId, ':admin_id' => $adminId]);
}

/**
 * Obtenir les demandes acceptées non encore provisionnées
 */
function getAcceptedDemandes(): array
{
    $pdo = getDB();
    $stmt = $pdo->query("
        SELECT d.*, u.username, u.ip_address 
        FROM demandes d
        JOIN users u ON u.id = d.user_id
        WHERE d.status = 'accepted'
          AND d.id NOT IN (
              SELECT DISTINCT demande_id FROM provision_logs WHERE action = 'provision' AND success = TRUE
          )
        ORDER BY d.created_at ASC
    ");
    return $stmt->fetchAll();
}

// ============================================================
// Fonctions pour les services (mail, samba, dns)
// ============================================================

/**
 * Créer un utilisateur mail virtuel (Postfix/Dovecot)
 */
function createVirtualUser(int $userId, string $email, string $password): int
{
    $pdo = getDB();
    
    // Hash SHA512-CRYPT pour Dovecot
    $salt = bin2hex(random_bytes(8));
    $dovecotHash = '{SHA512-CRYPT}' . crypt($password, '$6$' . $salt . '$');
    
    $domain = explode('@', $email)[1];
    $localPart = explode('@', $email)[0];
    $maildir = "/srv/mail/vhosts/$domain/$localPart";

    // Récupérer ou créer le domaine
    $stmt = $pdo->prepare("SELECT id FROM virtual_domains WHERE domain_name = :domain");
    $stmt->execute([':domain' => $domain]);
    $domainId = $stmt->fetchColumn();

    if (!$domainId) {
        $stmt = $pdo->prepare("INSERT INTO virtual_domains (domain_name) VALUES (:domain) RETURNING id");
        $stmt->execute([':domain' => $domain]);
        $domainId = $stmt->fetchColumn();
    }

    $stmt = $pdo->prepare("
        INSERT INTO virtual_users (domain_id, user_id, email, password, maildir)
        VALUES (:domain_id, :user_id, :email, :password, :maildir)
        RETURNING id
    ");
    $stmt->execute([
        ':domain_id' => $domainId,
        ':user_id'   => $userId,
        ':email'     => $email,
        ':password'  => $dovecotHash,
        ':maildir'   => $maildir,
    ]);

    return (int) $stmt->fetchColumn();
}

/**
 * Enregistrer un partage Samba
 */
function createSambaShare(int $userId, string $shareName, string $sharePath, string $group = 'users'): int
{
    $pdo = getDB();
    $stmt = $pdo->prepare("
        INSERT INTO samba_shares (user_id, share_name, share_path, samba_group)
        VALUES (:user_id, :share_name, :share_path, :samba_group)
        RETURNING id
    ");
    $stmt->execute([
        ':user_id'    => $userId,
        ':share_name' => $shareName,
        ':share_path' => $sharePath,
        ':samba_group' => $group,
    ]);

    return (int) $stmt->fetchColumn();
}

/**
 * Enregistrer un enregistrement DNS
 */
function createDnsRecord(int $userId, string $subdomain, string $ipAddress): int
{
    $pdo = getDB();
    $stmt = $pdo->prepare("
        INSERT INTO dns_records (user_id, subdomain, ip_address)
        VALUES (:user_id, :subdomain, :ip)
        RETURNING id
    ");
    $stmt->execute([
        ':user_id'   => $userId,
        ':subdomain' => $subdomain,
        ':ip'        => $ipAddress,
    ]);

    return (int) $stmt->fetchColumn();
}

/**
 * Ajouter un log de provisionnement
 */
function addProvisionLog(int $demandeId, int $userId, string $action, bool $success, string $message = ''): void
{
    $pdo = getDB();
    $stmt = $pdo->prepare("
        INSERT INTO provision_logs (demande_id, user_id, action, success, message)
        VALUES (:demande_id, :user_id, :action, :success, :message)
    ");
    $stmt->execute([
        ':demande_id' => $demandeId,
        ':user_id'    => $userId,
        ':action'     => $action,
        ':success'    => $success ? 'true' : 'false',
        ':message'    => $message,
    ]);
}

/**
 * Obtenir tous les services d'un utilisateur
 */
function getUserServices(int $userId): ?array
{
    $pdo = getDB();
    $stmt = $pdo->prepare("SELECT * FROM v_user_services WHERE id = :id");
    $stmt->execute([':id' => $userId]);
    return $stmt->fetch() ?: null;
}
