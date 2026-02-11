#!/usr/bin/env bash
# ============================================================
# Bubble.mg - Script d'initialisation de la base PostgreSQL
# Usage: sudo bash init_db.sh
# ============================================================
set -euo pipefail

# ── Configuration ──────────────────────────────────────────
DB_NAME="bubble"
DB_USER="bubble_user"
DB_PASS="bubble_secret_2026"   # À changer en production !
DB_HOST="127.0.0.1"
DB_PORT="5432"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCHEMA_FILE="$SCRIPT_DIR/schema.sql"

# ── Couleurs ───────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }

# ── Vérifications ─────────────────────────────────────────
echo "============================================"
echo "  Bubble.mg - Initialisation PostgreSQL"
echo "============================================"
echo ""

# Vérifier que PostgreSQL est installé
if ! command -v psql &> /dev/null; then
    warn "PostgreSQL n'est pas installé. Installation..."
    apt-get update -qq
    apt-get install -y postgresql postgresql-contrib php-pgsql
    systemctl enable postgresql
    systemctl start postgresql
    info "PostgreSQL installé et démarré"
else
    info "PostgreSQL détecté"
fi

# Vérifier que le service tourne
if ! systemctl is-active --quiet postgresql; then
    systemctl start postgresql
    info "PostgreSQL démarré"
fi

# ── Création de l'utilisateur PostgreSQL ──────────────────
echo ""
echo "── Création de l'utilisateur $DB_USER ──"

sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1 || {
    sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"
    info "Utilisateur '$DB_USER' créé"
}
info "Utilisateur '$DB_USER' prêt"

# ── Création de la base de données ────────────────────────
echo ""
echo "── Création de la base de données $DB_NAME ──"

if sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" | grep -q 1; then
    warn "La base '$DB_NAME' existe déjà"
    read -p "   Voulez-vous la supprimer et la recréer ? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo -u postgres psql -c "DROP DATABASE $DB_NAME;"
        info "Ancienne base supprimée"
    else
        warn "Conservation de la base existante. Arrêt du script."
        exit 0
    fi
fi

sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
info "Base de données '$DB_NAME' créée"

# ── Exécution du schéma SQL ───────────────────────────────
echo ""
echo "── Application du schéma SQL ──"

if [ ! -f "$SCHEMA_FILE" ]; then
    error "Fichier schema.sql introuvable: $SCHEMA_FILE"
fi

# Générer le hash bcrypt pour l'admin par défaut
ADMIN_HASH=$(php -r "echo password_hash('admin123', PASSWORD_BCRYPT);" 2>/dev/null || echo '$2y$10$defaulthashplaceholder')

# Remplacer le placeholder dans le schema
TEMP_SCHEMA=$(mktemp /tmp/bubble_schema.XXXXXX.sql)
sed "s|\\\$2y\\\$10\\\$YourBcryptHashHere|$ADMIN_HASH|g" "$SCHEMA_FILE" > "$TEMP_SCHEMA"
chmod 644 "$TEMP_SCHEMA"

sudo -u postgres psql -d "$DB_NAME" -f "$TEMP_SCHEMA"
rm -f "$TEMP_SCHEMA"

# Donner les droits sur toutes les tables
sudo -u postgres psql -d "$DB_NAME" -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $DB_USER;"
sudo -u postgres psql -d "$DB_NAME" -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $DB_USER;"
sudo -u postgres psql -d "$DB_NAME" -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO $DB_USER;"

info "Schéma SQL appliqué avec succès"

# ── Configurer pg_hba.conf pour les connexions locales ────
echo ""
echo "── Configuration des accès ──"

PG_HBA=$(sudo -u postgres psql -tc "SHOW hba_file" | xargs)

if ! grep -q "$DB_USER" "$PG_HBA" 2>/dev/null; then
    # Ajouter la ligne avant la première entrée existante
    echo "local   $DB_NAME    $DB_USER                            md5" | sudo tee -a "$PG_HBA" > /dev/null
    echo "host    $DB_NAME    $DB_USER    127.0.0.1/32            md5" | sudo tee -a "$PG_HBA" > /dev/null
    sudo systemctl reload postgresql
    info "Accès configuré dans pg_hba.conf"
else
    info "Accès déjà configuré"
fi

# ── Vérification ──────────────────────────────────────────
echo ""
echo "── Vérification ──"

TABLE_COUNT=$(sudo -u postgres psql -d "$DB_NAME" -tc "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE';" | xargs)
info "Nombre de tables créées: $TABLE_COUNT"

echo ""
echo "── Tables créées ──"
sudo -u postgres psql -d "$DB_NAME" -c "\dt"

echo ""
echo "============================================"
info "Base de données Bubble.mg initialisée !"
echo ""
echo "  Paramètres de connexion:"
echo "  ─────────────────────────"
echo "  Host:     $DB_HOST"
echo "  Port:     $DB_PORT"
echo "  Base:     $DB_NAME"
echo "  User:     $DB_USER"
echo "  Password: $DB_PASS"
echo ""
echo "  Admin web par défaut:"
echo "  ─────────────────────"
echo "  Username: admin"
echo "  Password: admin123"
echo ""
echo "  ⚠  Changez les mots de passe en production !"
echo "============================================"
