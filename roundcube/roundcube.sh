sudo cp -R usr.share/roundcube /usr/share/roundcube
sudo chown -R www-data:www-data /usr/share/roundcube
sudo cp -R etc/roundcube /etc/roundcube
sudo chown -R www-data:www-data /etc/roundcube
sudo chmod -R 755 etc/roundcube
sudo cp -R apache2/conf-available/roundcube.conf /etc/apache2/conf-available/roundcube.conf
sudo chmod -R 755 /usr/share/roundcube
sudo cp -R apache2/conf-enabled/roundcube.conf /etc/apache2/conf-enabled/roundcube.conf
sudo cp -R apache2/conf-available/roundcube.conf /etc/apache2/conf-available/roundcube.conf
sudo cp -R apache2/sites-available/roundcube.conf /etc/apache2/sites-available/roundcube.conf
sudo cp -R apache2/sites-enabled/roundcube.conf /etc/apache2/sites-enabled/roundcube.conf
sudo chmod 755 /etc/apache2/conf-available /etc/apache2/conf-enabled /etc/apache2/sites-available /etc/apache2/sites-enabled
sudo a2ensite roundcube.conf
sudo a2enconf roundcube.conf
sudo a2enmod rewrite
sudo systemctl reload apache2
sudo systemctl reload apache2