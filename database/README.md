# Bubble.mg - Base de données PostgreSQL

## Architecture de la base de données

### Diagramme des tables

```
┌──────────────────────┐
│       users          │
├──────────────────────┤
│ id (PK)              │
│ username (UNIQUE)    │
│ password_hash        │
│ email (UNIQUE)       │
│ full_name            │
│ ip_address           │
│ status (enum)        │──── en_attente / valide / suspendu
│ is_admin             │
│ created_at           │
│ updated_at           │
└──────┬───────────────┘
       │
       │ 1:N
       ▼
┌──────────────────────┐      ┌──────────────────────┐
│     demandes         │      │   provision_logs     │
├──────────────────────┤      ├──────────────────────┤
│ id (PK)              │◄─────│ demande_id (FK)      │
│ user_id (FK)         │      │ user_id (FK)         │
│ sous_domaine         │      │ action               │
│ mail (bool)          │      │ success              │
│ samba (bool)          │      │ message              │
│ status (enum)        │──── pending / accepted / rejected
│ reviewed_by (FK)     │      │ executed_at          │
│ reviewed_at          │      └──────────────────────┘
│ created_at           │
└──────────────────────┘

┌──────────────────────┐      ┌──────────────────────┐
│  virtual_domains     │      │   virtual_users      │
├──────────────────────┤      ├──────────────────────┤
│ id (PK)              │◄─────│ domain_id (FK)       │
│ domain_name (UNIQUE) │      │ user_id (FK → users) │
└──────────────────────┘      │ email (UNIQUE)       │
                              │ password (SHA512)    │
┌──────────────────────┐      │ maildir              │
│  virtual_aliases     │      │ quota                │
├──────────────────────┤      │ enabled              │
│ domain_id (FK)       │      └──────────────────────┘
│ source               │
│ destination          │      ┌──────────────────────┐
└──────────────────────┘      │   samba_shares       │
                              ├──────────────────────┤
┌──────────────────────┐      │ user_id (FK → users) │
│    dns_records       │      │ share_name           │
├──────────────────────┤      │ share_path           │
│ user_id (FK → users) │      │ samba_group          │
│ subdomain (UNIQUE)   │      │ samba_password_set   │
│ record_type          │      │ browseable           │
│ ip_address           │      │ writable             │
│ fqdn (GENERATED)     │      │ enabled              │
└──────────────────────┘      └──────────────────────┘
```

## Installation

### Prérequis
- PostgreSQL 14+
- PHP 8.0+ avec extension `php-pgsql`
- Accès root/sudo sur le serveur

### Étapes

```bash
# 1. Rendre le script exécutable
chmod +x database/init_db.sh

# 2. Exécuter le script d'initialisation
sudo bash database/init_db.sh
```

Le script va automatiquement :
- Installer PostgreSQL si absent
- Créer l'utilisateur `bubble_user`
- Créer la base `bubble`
- Appliquer le schéma (toutes les tables)
- Configurer les accès dans `pg_hba.conf`
- Créer un compte admin par défaut

## Paramètres de connexion

| Paramètre | Valeur             |
|-----------|-------------------|
| Host      | `127.0.0.1`       |
| Port      | `5432`            |
| Base      | `bubble`          |
| User      | `bubble_user`     |
| Password  | `bubble_secret_2026` |

## Tables

### `users` — Comptes utilisateurs Bubble
Stocke tous les utilisateurs avec leur statut de validation :
- `en_attente` : inscription en cours, pas encore validé par l'admin
- `valide` : validé par l'admin, services provisionnés
- `suspendu` : compte désactivé

### `demandes` — Demandes de services
Chaque utilisateur peut demander :
- Un **sous-domaine** (ex: `sarobidy.bubble.mg`)
- Un accès **mail** (Postfix/Dovecot)
- Un partage **Samba**

Statuts : `pending` → `accepted` / `rejected`

### `virtual_domains` — Domaines mail (Postfix)
Domaines gérés par le serveur mail. Le domaine `bubble.mg` est inséré par défaut.

### `virtual_users` — Utilisateurs mail (Dovecot)
Comptes mail virtuels avec mot de passe SHA512-CRYPT pour l'authentification Dovecot SQL.

### `virtual_aliases` — Alias mail
Redirections d'email (ex: `contact@bubble.mg` → `admin@bubble.mg`).

### `samba_shares` — Partages Samba
Enregistrement des partages créés pour chaque utilisateur.

### `dns_records` — Enregistrements DNS
Sous-domaines créés dans BIND9. Le champ `fqdn` est généré automatiquement.

### `provision_logs` — Logs de provisionnement
Trace de toutes les actions de provisionnement (DNS, mail, samba).

## Utilisation dans le code PHP

```php
<?php
require_once __DIR__ . '/core/db.php';

// Créer un utilisateur
$userId = createUser('sarobidy', 'motdepasse', 'sarobidy@bubble.mg', 'Sarobidy R.');

// Authentifier
$user = authenticateUser('sarobidy', 'motdepasse');

// Créer une demande
$demandeId = createDemande($userId, 'sarobidy', true, true);

// Admin : lister les demandes en attente
$pending = getPendingDemandes();

// Admin : accepter une demande
acceptDemande($demandeId, $adminId);

// Provisionnement : créer les services
createDnsRecord($userId, 'sarobidy', '10.228.55.100');
createVirtualUser($userId, 'sarobidy@bubble.mg', 'motdepasse');
createSambaShare($userId, 'partage', '/home/sarobidy/partage');

// Logger le provisionnement
addProvisionLog($demandeId, $userId, 'provision', true, 'OK');
```

## Vues SQL

- **`v_demandes_pending`** : Demandes en attente avec infos utilisateur
- **`v_user_services`** : Vue complète des services d'un utilisateur (mail, samba, DNS)

## Configuration Dovecot

Le fichier `dovecot-sql.conf.ext` a été mis à jour pour utiliser PostgreSQL :

```ini
driver = pgsql
connect = host=127.0.0.1 dbname=bubble user=bubble_user password=bubble_secret_2026
default_pass_scheme = SHA512-CRYPT
password_query = SELECT email AS user, password FROM virtual_users WHERE email='%u' AND enabled = TRUE;
user_query = SELECT maildir AS home, 5000 AS uid, 5000 AS gid FROM virtual_users WHERE email='%u' AND enabled = TRUE;
```

## Commandes utiles

```bash
# Se connecter à la base
psql -h 127.0.0.1 -U bubble_user -d bubble

# Lister les utilisateurs
SELECT username, status, created_at FROM users;

# Voir les demandes en attente
SELECT * FROM v_demandes_pending;

# Voir les services d'un utilisateur
SELECT * FROM v_user_services WHERE username = 'sarobidy';
```
