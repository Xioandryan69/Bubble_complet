Internet
   |
   v
Postfix  (SMTP : reçoit / envoie)
   |
   v
Maildir (/home/user/Maildir)
   |
   v
Dovecot (IMAP/POP3 : lecture des mails)

sudo nano /etc/postfix/main.cf

echo "bubble.mg" | sudo tee /etc/mailname

