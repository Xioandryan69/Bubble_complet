sudo cp Bubble_complet/Bubble/provision.sh /usr/local/bin/
sudo cp Bubble_complet/VirtualHost/serveur/user.sh /usr/local/bin/
sudo cp Bubble_complet/Samba/run.sh /usr/local/bin/samba_add.sh

sudo chmod 750 /usr/local/bin/provision.sh
sudo chmod 750 /usr/local/bin/user.sh
sudo chmod 750 /usr/local/bin/samba_add.sh

chown root:root /usr/local/bin/{provision.sh,user.sh,samba_add.sh}
chmod 750 /usr/local/bin/{provision.sh,user.sh,samba_add.sh}

