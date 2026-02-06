cp ../main.cf /etc/postfix/main.cf
sudo chown -R itu:itu /etc/postfix/main.cf

echo "bubble.mg" | sudo tee /etc/mailname
sudo chown -R itu:itu /etc/mailname

sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
-keyout /etc/ssl/private/mail.key \
-out /etc/ssl/certs/mail.crt \
-subj "/CN=mail.bubble.mg"
sudo chown -R itu:itu /etc/ssl/private/mail.key
sudo chown -R itu:itu /etc/ssl/certs/mail.crt

sudo systemctl restart postfix
sudo systemctl enable postfix

sudo systemctl restart dovecot
sudo systemctl enable dovecot

sudo ufw allow 25     # SMTP
sudo ufw allow 587    # SMTP submission
sudo ufw allow 110    # POP3
sudo ufw allow 143    # IMAP
sudo ufw allow 993    # IMAPS
sudo ufw allow 995    # POP3S
