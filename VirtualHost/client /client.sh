echo "Copying db.bubble.mg to /etc/bind/..."
sudo cp db.bubble.mg /etc/bind/
chown root:bind /etc/bind/db.bubble.mg
chmod 640 /etc/bind/db.bubble.mg

sudo chown -R itu:itu /etc/bind/named.conf.local
# Ensure the zone file ends with a newline to avoid BIND parse errors.
sudo sed -i -e '$a\' /etc/bind/db.bubble.mg
echo "Configuring BIND9 for bubble.mg... /etc/bind/named.conf.local"
# Add the zone only once to avoid duplicate definition errors.
if ! grep -q 'zone "bubble.mg"' /etc/bind/named.conf.local; then
cat <<EOF | sudo tee -a /etc/bind/named.conf.local > /dev/null

zone "bubble.mg" {
        type master;
        file "/etc/bind/db.bubble.mg";
};
EOF
else
    echo "Zone bubble.mg already present in /etc/bind/named.conf.local"
fi

sudo named-checkconf
sudo named-checkzone bubble.mg /etc/bind/db.bubble.mg
sudo systemctl restart bind9

dig bubble.mg

sudo cp -r ../../Bubble /var/www/html/Bubble

sudo chown root:root /var/www/html/Bubble

sudo cp ../bubble.mg.conf /etc/apache2/sites-available/bubble.mg.conf
#sudo nano /etc/apache2/sites-available/bubble.mg.conf
sudo chown root:root /etc/apache2/sites-available/bubble.mg.conf

sudo a2ensite bubble.mg.conf
sudo systemctl reload apache2



echo "http://bubble.mg"

sudo mkdir -p /etc/apache2/ssl
sudo openssl req -x509 -nodes -days 365 \
-newkey rsa:2048 \
-keyout /etc/apache2/ssl/bubble.mg.key \
-out /etc/apache2/ssl/bubble.mg.crt
sudo chown root:root /etc/apache2/ssl/bubble.mg.key
sudo chmod 600 /etc/apache2/ssl/bubble.mg.key
sudo chown root:root /etc/apache2/ssl/bubble.mg.crt
sudo chmod 644 /etc/apache2/ssl/bubble.mg.crt
sudo cp ../../bubble.mg-ssl.conf /etc/apache2/sites-available/bubble.mg-ssl.conf
sudo chown root:root /etc/apache2/sites-available/bubble.mg-ssl.conf

sudo nano /etc/apache2/sites-available/bubble.mg-ssl.conf


sudo a2enmod ssl
sudo a2ensite bubble.mg-ssl.conf
sudo systemctl restart apache2
