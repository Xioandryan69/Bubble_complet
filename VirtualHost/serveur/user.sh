# fonction a deux arguments 
if [ "$#" -ne 2 ]; then
    echo " Usage incorrect"
    echo " Usage: $0 <username> <ip>"
    exit 1
fi

USERNAME="$1"
IP="$2"
DOMAIN="bubble.mg"
ZONE_FILE="/etc/bind/db.bubble.mg"
sudo chown -R itu:itu "$ZONE_FILE"
# 2️ Vérifier si l'entrée existe déjà
if grep -qE "^$USERNAME\s+IN\s+A" "$ZONE_FILE"; then
    echo "  L'entrée DNS $USERNAME.$DOMAIN existe déjà"
    exit 0
fi

# 3️ Ajouter l’entrée DNS
echo " Ajout DNS : $USERNAME.$DOMAIN → $IP"
echo "$USERNAME    IN    A    $IP" | sudo tee -a "$ZONE_FILE" > /dev/null

# 4️ Incrémenter le Serial
echo " Mise à jour du Serial"
sudo sed -i '/Serial/ s/\([0-9]\+\)/\1+1/e' "$ZONE_FILE"

# 5️ Vérification de la zone
echo " Vérification BIND9..."
sudo chown -R itu:itu "$ZONE_FILE"
sudo named-checkzone "$DOMAIN" "$ZONE_FILE"
if [ $? -ne 0 ]; then
    echo " Erreur dans le fichier DNS"
    exit 1
fi

# 6️ Redémarrage BIND9
echo " Redémarrage de BIND9"
sudo systemctl restart bind9

echo " DNS ajouté avec succès : $USERNAME.$DOMAIN"
