sudo nano /etc/bind/zones/db.bubble.mg

nyavo    IN    A    10.228.55.227
$USERNAME IN    A    $ip

sudo systemctl restart bind9

sudo adduser nyavo

#cree 
sudo -u nyavo maildirmake /home/nyavo/Maildir

#ou cree si elle existe pas deja
sudo mkdir -p /home/nyavo/Maildir/{cur,new,tmp}
sudo chown -R nyavo:nyavo /home/nyavo/Maildir


@       IN   MX   10 mail.bubble.mg.
mail    IN   A        10.228.55.227

 sudo ./user.sh nyavo 192.168.1.1
 
sudo systemctl restart bind9
