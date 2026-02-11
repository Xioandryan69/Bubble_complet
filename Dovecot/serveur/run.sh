cp ../main.cf /etc/postfix/main.cf
sudo chown  root:root /etc/postfix/main.cf

echo "bubble.mg" | sudo tee /etc/mailname
sudo chown root:root /etc/mailname
sudo chmod 644 /etc/mailname

sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
-keyout /etc/ssl/private/mail.key \
-out /etc/ssl/certs/mail.crt \
-subj "/CN=mail.bubble.mg"
sudo chown  root:root /etc/ssl/private/mail.key
sudo chmod 600 /etc/ssl/private/mail.key
sudo chown  root:root /etc/ssl/certs/mail.crt
sudo chmod 644 /etc/ssl/certs/mail.crt

sudo systemctl restart postfix
sudo systemctl enable postfix

sudo cp -R ../dovecot/* /etc/dovecot/
sudo chown -R root:root /etc/dovecot
sudo chmod 755 /etc/dovecot
sudo systemctl restart dovecot
sudo systemctl enable dovecot

sudo ufw allow 25     # SMTP
sudo ufw allow 587    # SMTP submission
sudo ufw allow 110    # POP3
sudo ufw allow 143    # IMAP
sudo ufw allow 993    # IMAPS
sudo ufw allow 995    # POP3S
