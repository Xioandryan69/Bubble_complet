# Crée le dossier
if [ "$#" -ne 2 ]; then
    echo " Usage incorrect"
    echo "👉 Usage: $0 <username> <partage>"
    exit 1
fi
username="$1"
partage="$2"

sudo mkdir -p /home/"$username"/"$partage"
sudo chown -R itu:itu /home/"$username"/"$partage"

# Change le propriétaire pour l'utilisateur nyavo
sudo chown "$username":"$username" /home/"$username"/"$partage"

# Met des permissions de base (lecture/écriture/exécution pour le propriétaire)
sudo chmod 750 /home/"$username"/"$partage"

# Crée l'utilisateur Samba (il existe déjà sous Linux)
sudo smbpasswd -a "$username"

# Active l’utilisateur Samba
sudo smbpasswd -e "$username"

# Redémarrer Samba
sudo systemctl restart smbd
sudo systemctl restart nmbd
echo "Partage Samba créé pour l'utilisateur $username : //$HOSTNAME/$partage"
