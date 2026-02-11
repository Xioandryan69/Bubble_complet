-- ============================================================
-- Bubble.mg - Schéma PostgreSQL
-- Base de données pour la gestion des utilisateurs,
-- leurs demandes (en attente / validées / refusées),
-- et les données Postfix, Dovecot et Samba.
-- ============================================================

-- Créer la base de données (à exécuter en tant que superuser)
-- CREATE DATABASE bubble;

-- Se connecter à la base bubble avant d'exécuter le reste
-- \c bubble

-- ============================================================
-- 1. TYPES ENUM
-- ============================================================

-- Statut d'une demande utilisateur
CREATE TYPE demande_status AS ENUM ('pending', 'accepted', 'rejected');

-- Statut global d'un utilisateur
CREATE TYPE user_status AS ENUM ('en_attente', 'valide', 'suspendu');

-- ============================================================
-- 2. TABLE UTILISATEURS (comptes Bubble)
-- ============================================================

CREATE TABLE users (
    id              SERIAL PRIMARY KEY,
    username        VARCHAR(50)  UNIQUE NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,           -- mot de passe hashé (bcrypt)
    email           VARCHAR(150) UNIQUE,
    full_name       VARCHAR(100),
    ip_address      INET,                            -- adresse IP attribuée
    status          user_status  NOT NULL DEFAULT 'en_attente',
    is_admin        BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- Index pour recherche rapide par statut
CREATE INDEX idx_users_status ON users(status);

-- ============================================================
-- 3. TABLE DEMANDES (sous-domaine, mail, samba)
-- ============================================================

CREATE TABLE demandes (
    id              SERIAL PRIMARY KEY,
    user_id         INTEGER      NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    sous_domaine    VARCHAR(100) NOT NULL,            -- ex: "sarobidy" → sarobidy.bubble.mg
    mail            BOOLEAN      NOT NULL DEFAULT FALSE,
    samba           BOOLEAN      NOT NULL DEFAULT FALSE,
    status          demande_status NOT NULL DEFAULT 'pending',
    reviewed_by     INTEGER      REFERENCES users(id),  -- admin qui a traité
    reviewed_at     TIMESTAMP,
    created_at      TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_demandes_status ON demandes(status);
CREATE INDEX idx_demandes_user   ON demandes(user_id);

-- ============================================================
-- 4. TABLES POSTFIX / DOVECOT (mail virtuel)
-- ============================================================

-- 4a. Domaines virtuels gérés par Postfix
CREATE TABLE virtual_domains (
    id              SERIAL PRIMARY KEY,
    domain_name     VARCHAR(100) UNIQUE NOT NULL      -- ex: bubble.mg
);

-- Insérer le domaine principal
INSERT INTO virtual_domains (domain_name) VALUES ('bubble.mg');

-- 4b. Utilisateurs mail virtuels (Dovecot auth SQL)
CREATE TABLE virtual_users (
    id              SERIAL PRIMARY KEY,
    domain_id       INTEGER      NOT NULL REFERENCES virtual_domains(id) ON DELETE CASCADE,
    user_id         INTEGER      REFERENCES users(id) ON DELETE SET NULL,
    email           VARCHAR(150) UNIQUE NOT NULL,     -- ex: sarobidy@bubble.mg
    password        VARCHAR(255) NOT NULL,            -- SHA512-CRYPT pour Dovecot
    maildir         VARCHAR(255) NOT NULL,            -- ex: /srv/mail/vhosts/bubble.mg/sarobidy
    quota           BIGINT       DEFAULT 0,           -- quota en octets (0 = illimité)
    enabled         BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_virtual_users_email ON virtual_users(email);

-- 4c. Alias mail virtuels
CREATE TABLE virtual_aliases (
    id              SERIAL PRIMARY KEY,
    domain_id       INTEGER      NOT NULL REFERENCES virtual_domains(id) ON DELETE CASCADE,
    source          VARCHAR(150) NOT NULL,            -- ex: contact@bubble.mg
    destination     VARCHAR(150) NOT NULL,            -- ex: sarobidy@bubble.mg
    created_at      TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_virtual_aliases_source ON virtual_aliases(source);

-- ============================================================
-- 5. TABLE SAMBA (partages utilisateur)
-- ============================================================

CREATE TABLE samba_shares (
    id              SERIAL PRIMARY KEY,
    user_id         INTEGER      NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    share_name      VARCHAR(100) NOT NULL,            -- nom du partage Samba
    share_path      VARCHAR(255) NOT NULL,            -- ex: /home/sarobidy/partage
    samba_group     VARCHAR(50)  DEFAULT 'users',     -- groupe Samba
    samba_password_set BOOLEAN   NOT NULL DEFAULT FALSE,
    browseable      BOOLEAN      NOT NULL DEFAULT TRUE,
    writable        BOOLEAN      NOT NULL DEFAULT TRUE,
    enabled         BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_samba_shares_user ON samba_shares(user_id);

-- ============================================================
-- 6. TABLE DNS (enregistrements créés)
-- ============================================================

CREATE TABLE dns_records (
    id              SERIAL PRIMARY KEY,
    user_id         INTEGER      NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subdomain       VARCHAR(100) NOT NULL,            -- ex: sarobidy
    record_type     VARCHAR(10)  NOT NULL DEFAULT 'A',
    ip_address      INET         NOT NULL,
    fqdn            VARCHAR(200) GENERATED ALWAYS AS (subdomain || '.bubble.mg') STORED,
    created_at      TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_dns_records_subdomain ON dns_records(subdomain);

-- ============================================================
-- 7. TABLE LOGS (provisionnement)
-- ============================================================

CREATE TABLE provision_logs (
    id              SERIAL PRIMARY KEY,
    demande_id      INTEGER      NOT NULL REFERENCES demandes(id) ON DELETE CASCADE,
    user_id         INTEGER      NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    action          VARCHAR(50)  NOT NULL,            -- 'dns', 'mail', 'samba', 'provision'
    success         BOOLEAN      NOT NULL DEFAULT TRUE,
    message         TEXT,
    executed_at     TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_provision_logs_demande ON provision_logs(demande_id);

-- ============================================================
-- 8. FONCTIONS UTILITAIRES
-- ============================================================

-- Mise à jour automatique du champ updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_demandes_updated_at
    BEFORE UPDATE ON demandes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- 9. ADMIN PAR DÉFAUT
-- ============================================================

-- Mot de passe: admin123 (à changer en production !)
-- Hash bcrypt de 'admin123'
INSERT INTO users (username, password_hash, email, full_name, status, is_admin)
VALUES (
    'admin',
    '$2y$10$YourBcryptHashHere',
    'admin@bubble.mg',
    'Administrateur Bubble',
    'valide',
    TRUE
);

-- ============================================================
-- 10. VUES UTILES
-- ============================================================

-- Vue des demandes en attente avec info utilisateur
CREATE VIEW v_demandes_pending AS
SELECT
    d.id            AS demande_id,
    u.username,
    u.full_name,
    u.ip_address,
    d.sous_domaine,
    d.mail,
    d.samba,
    d.status,
    d.created_at
FROM demandes d
JOIN users u ON u.id = d.user_id
WHERE d.status = 'pending'
ORDER BY d.created_at ASC;

-- Vue complète d'un utilisateur avec ses services
CREATE VIEW v_user_services AS
SELECT
    u.id,
    u.username,
    u.email,
    u.status       AS user_status,
    u.ip_address,
    vu.email       AS mail_address,
    vu.enabled     AS mail_enabled,
    ss.share_name  AS samba_share,
    ss.share_path  AS samba_path,
    ss.enabled     AS samba_enabled,
    dr.fqdn        AS dns_fqdn
FROM users u
LEFT JOIN virtual_users vu ON vu.user_id = u.id
LEFT JOIN samba_shares ss  ON ss.user_id = u.id
LEFT JOIN dns_records dr   ON dr.user_id = u.id;

-- ============================================================
-- REQUÊTES DOVECOT (référence pour dovecot-sql.conf.ext)
-- ============================================================
-- password_query:
--   SELECT email AS user, password
--   FROM virtual_users
--   WHERE email = '%u' AND enabled = TRUE;
--
-- user_query:
--   SELECT maildir AS home, 5000 AS uid, 5000 AS gid
--   FROM virtual_users
--   WHERE email = '%u' AND enabled = TRUE;
-- ============================================================

--psql -h 127.0.0.1 -U bubble_user -d bubble