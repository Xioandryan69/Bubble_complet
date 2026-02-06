[] ARCHITECTURE:
    1 serveur DNS/Web (192.168.1.1)
    3 clients (réseau local)

    Domaine :: bubble.mg + www.bubble.mg
    HTTP (80) + HTTPS (443)

    résolution DNS : BIND9 (ns.bubble.mg @ 192.168.1.1)
    Contenu Apache : /var/www/html/Bubble


[] CLIENTS (3x) - ajouter nameserver:
    echo "nameserver 192.168.1.1" | sudo tee -a /etc/resolv.conf
    
    Vérifier:
    dig bubble.mg
    dig www.bubble.mg
    nslookup bubble.mg 192.168.1.1





[]Declarer zone :
    [] creer db.bubble.mg

-------------------

    $TTL    604800
@       IN      SOA     ns.bubble.mg. admin.bubble.mg. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL

@       IN      NS      ns.bubble.mg.
ns      IN      A       192.168.1.1

@       IN      A       192.168.1.1
www     IN      A       192.168.1.1
serveur IN      A       192.168.1.1
client  IN      A       192.168.1.1
--------------------------


    [] ajouter la zone
    
    /etc/bind/named.conf.local :

    zone "bubble.mg" {
            type master;
            file "/etc/bind/db.bubble.mg";
        };