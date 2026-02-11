-- ============================================================
-- Bubble.mg - Données de test (5 utilisateurs)
-- Usage: sudo -u postgres psql -d bubble -f test_data.sql
-- ============================================================

-- Mot de passe pour tous les utilisateurs de test : "test1234"
-- Hash bcrypt de "test1234"

-- ============================================================
-- 1. UTILISATEURS
-- ============================================================

-- 3 en attente, 2 déjà validés
INSERT INTO users (username, password_hash, email, full_name, status, ip_address, is_admin) VALUES
('sarobidy',  '$2y$10$LK8HXx0YGz5KR7Gqh1QJXOZx3KjV4BqZJd5mN8wRfE6YzA1hS0XOe', 'sarobidy@bubble.mg',  'Sarobidy Rakoto',     'en_attente', NULL,              FALSE),
('yoan',      '$2y$10$LK8HXx0YGz5KR7Gqh1QJXOZx3KjV4BqZJd5mN8wRfE6YzA1hS0XOe', 'yoan@bubble.mg',      'Yoan Andriantsoa',    'en_attente', NULL,              FALSE),
('mendrika',  '$2y$10$LK8HXx0YGz5KR7Gqh1QJXOZx3KjV4BqZJd5mN8wRfE6YzA1hS0XOe', 'mendrika@bubble.mg',  'Mendrika Rasolofon',  'en_attente', NULL,              FALSE),
('tsoa',      '$2y$10$LK8HXx0YGz5KR7Gqh1QJXOZx3KjV4BqZJd5mN8wRfE6YzA1hS0XOe', 'tsoa@bubble.mg',      'Tsoa Ramanantsoa',    'valide',     '10.228.55.100',   FALSE),
('nyavo', '$2y$10$LK8HXx0YGz5KR7Gqh1QJXOZx3KjV4BqZJd5mN8wRfE6YzA1hS0XOe', 'nyavo@bubble.mg', 'Nyavo Ravelona',  'valide',     '10.228.55.101',   FALSE);

-- ============================================================
-- 2. DEMANDES
-- ============================================================

-- Demandes en attente (pour les 3 users en_attente)
INSERT INTO demandes (user_id, sous_domaine, mail, samba, status) VALUES
((SELECT id FROM users WHERE username='sarobidy'),  'sarobidy',  TRUE,  TRUE,  'pending'),
((SELECT id FROM users WHERE username='yoan'),      'yoan',      TRUE,  FALSE, 'pending'),
((SELECT id FROM users WHERE username='mendrika'),  'mendrika',  FALSE, TRUE,  'pending');

-- Demandes acceptées (pour les 2 users validés)
INSERT INTO demandes (user_id, sous_domaine, mail, samba, status, reviewed_by, reviewed_at) VALUES
((SELECT id FROM users WHERE username='tsoa'),      'tsoa',      TRUE,  TRUE,  'accepted', (SELECT id FROM users WHERE username='admin'), NOW()),
((SELECT id FROM users WHERE username='nyavo'), 'nyavo', TRUE,  TRUE,  'accepted', (SELECT id FROM users WHERE username='admin'), NOW());

-- ============================================================
-- 3. DNS (pour les users validés)
-- ============================================================

INSERT INTO dns_records (user_id, subdomain, ip_address) VALUES
((SELECT id FROM users WHERE username='tsoa'),      'tsoa',      '10.228.55.100'),
((SELECT id FROM users WHERE username='nyavo'), 'nyavo', '10.228.55.101');

-- ============================================================
-- 4. MAIL / DOVECOT (pour les users validés)
-- ============================================================

-- Hash SHA512-CRYPT de "test1234"
INSERT INTO virtual_users (domain_id, user_id, email, password, maildir, enabled) VALUES
(1, (SELECT id FROM users WHERE username='tsoa'),      'tsoa@bubble.mg',      '{SHA512-CRYPT}$6$abc123$hashedpassword', '/srv/mail/vhosts/bubble.mg/tsoa',      TRUE),
(1, (SELECT id FROM users WHERE username='nyavo'), 'nyavo@bubble.mg', '{SHA512-CRYPT}$6$def456$hashedpassword', '/srv/mail/vhosts/bubble.mg/nyavo', TRUE);

-- ============================================================
-- 5. SAMBA (pour les users validés)
-- ============================================================

INSERT INTO samba_shares (user_id, share_name, share_path, samba_group, samba_password_set, enabled) VALUES
((SELECT id FROM users WHERE username='tsoa'),      'PartageT',  '/home/tsoa/partage',      'users', TRUE, TRUE),
((SELECT id FROM users WHERE username='nyavo'), 'PartageS',  '/home/nyavo/partage', 'users', TRUE, TRUE);

-- ============================================================
-- 6. LOGS (provisionnement des users validés)
-- ============================================================

INSERT INTO provision_logs (demande_id, user_id, action, success, message) VALUES
((SELECT id FROM demandes WHERE sous_domaine='tsoa'      AND status='accepted'), (SELECT id FROM users WHERE username='tsoa'),      'dns',       TRUE, 'DNS tsoa.bubble.mg → 10.228.55.100'),
((SELECT id FROM demandes WHERE sous_domaine='tsoa'      AND status='accepted'), (SELECT id FROM users WHERE username='tsoa'),      'mail',      TRUE, 'Maildir créé /srv/mail/vhosts/bubble.mg/tsoa'),
((SELECT id FROM demandes WHERE sous_domaine='tsoa'      AND status='accepted'), (SELECT id FROM users WHERE username='tsoa'),      'samba',     TRUE, 'Partage /home/tsoa/partage créé'),
((SELECT id FROM demandes WHERE sous_domaine='tsoa'      AND status='accepted'), (SELECT id FROM users WHERE username='tsoa'),      'provision', TRUE, 'Provisionnement complet'),
((SELECT id FROM demandes WHERE sous_domaine='nyavo' AND status='accepted'), (SELECT id FROM users WHERE username='nyavo'), 'dns',       TRUE, 'DNS nyavo.bubble.mg → 10.228.55.101'),
((SELECT id FROM demandes WHERE sous_domaine='nyavo' AND status='accepted'), (SELECT id FROM users WHERE username='nyavo'), 'mail',      TRUE, 'Maildir créé /srv/mail/vhosts/bubble.mg/nyavo'),
((SELECT id FROM demandes WHERE sous_domaine='nyavo' AND status='accepted'), (SELECT id FROM users WHERE username='nyavo'), 'samba',     TRUE, 'Partage /home/nyavo/partage créé'),
((SELECT id FROM demandes WHERE sous_domaine='nyavo' AND status='accepted'), (SELECT id FROM users WHERE username='nyavo'), 'provision', TRUE, 'Provisionnement complet');

-- ============================================================
-- Vérification
-- ============================================================
SELECT '── Utilisateurs ──' AS info;
SELECT id, username, status, ip_address FROM users WHERE username != 'admin' ORDER BY id;

SELECT '── Demandes ──' AS info;
SELECT d.id, u.username, d.sous_domaine, d.mail, d.samba, d.status FROM demandes d JOIN users u ON u.id = d.user_id ORDER BY d.id;

SELECT '── Services (users validés) ──' AS info;
SELECT * FROM v_user_services WHERE username IN ('tsoa', 'nyavo');
