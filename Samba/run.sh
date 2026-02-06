# Crée le dossier
sudo mkdir -p /home/nyavo/partage

# Change le propriétaire pour l'utilisateur nyavo
sudo chown nyavo:nyavo /home/nyavo/partage

# Met des permissions de base (lecture/écriture/exécution pour le propriétaire)
sudo chmod 750 /home/nyavo/partage

# Crée l'utilisateur Samba (il existe déjà sous Linux)
sudo smbpasswd -a nyavo

# Active l’utilisateur Samba
sudo smbpasswd -e nyavo
