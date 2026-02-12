[]Utilisateur

    Connexion:


    Demande :

        sous-domaine
        mail
        espace samba
demandes (
    id INT AUTO_INCREMENT,
    username VARCHAR(50),
    sous_domaine VARCHAR(100),
    mail BOOLEAN,
    samba BOOLEAN,
    status ENUM('pending','accepted','rejected'),
    created_at TIMESTAMP
);

Admin

        Valide / refuse

        Crée automatiquement :

                DNS

                Maildir

                Samba<>

                Dossier web

        Liste des demandes

        Vérification

        Bouton ACCEPTER

Provision.php

        Récupère les demandes validées

        Crée les ressources nécessaires
        
        exec("/usr/local/bin/provision.sh $username $ip");

copier scripts dans /usr/local/bin() sans sudo 
sudo cp -R provision.sh /usr/local/bin/provision.sh
sudo cp -R /home/itu/Documents/S3/Reseaux/Bubble_complet/VirtualHost/client /user.sh /usr/local/bin/user.sh

sudo cp -R /home/itu/Documents/S3/Reseaux/Bubble_complet/Samba/run.sh /usr/local/bin/samba_add.sh

---------------------------
#!/usr/bin/env bash
set -euo pipefail

USERNAME="$1"
IP="$2"

# 1. DNS Mail Web
/usr/local/bin/user.sh "$USERNAME" "$IP"



# 3. Samba
/usr/local/bin/samba_add.sh "$USERNAME" "GROUP"




------------------------

Structure 
            Bubble/
        ├── public/
        │   ├── index.php
        │   ├── connexion.php
        │   └── modele.php
        ├── admin/
        │   └── admin.php
        ├── services/
        │   ├── mail.php
        │   ├── samba.php
        │   └── dns.php
        ├── core/
        │   ├── auth.php
        │   ├── validator.php
        │   └── logger.php
        └── api/
            └── provision.php

------------------------

README - Guide d'utilisation (ne change rien au code)

Objectif
        Centraliser les demandes utilisateur (sous-domaine, mail, samba), puis
        permettre a l'admin de valider et declencher le provisionnement.

Fonctionnalites
        Utilisateur
                - Connexion
                - Formulaire de demande: sous-domaine, mail, samba
                - Enregistrement en base (table demandes)

        Admin
                - Liste des demandes
                - Validation / refus
                - Bouton ACCEPTER pour declencher le provisionnement

        Provisionnement
                - provision.php recupere les demandes validees
                - provision.php appelle /usr/local/bin/provision.sh

Ce qu'il faut faire (pas a pas)
        1) Base de donnees
                - Creer la table demandes (schema deja note plus haut)

        2) Scripts systeme
                - Copier les scripts dans /usr/local/bin (voir commandes ci-dessus)
                - Verifier les droits d'execution (chmod +x)

        3) Fichiers de configuration
                - VirtualHost: DNS + web
                - Dovecot: mail
                - Samba: partage

        4) Utilisation
                - L'utilisateur soumet sa demande
                - L'admin valide
                - provision.php appelle provision.sh
                - provision.sh appelle user.sh et samba_add.sh

Structure et roles des dossiers (resume)
        Bubble/public
                - Pages publiques (index, connexion, modele)
        Bubble/admin
                - Interface admin
        Bubble/services
                - Services de provisionnement (mail, samba, dns)
        Bubble/core
                - Auth, validation, logs
        Bubble/api
                - Points d'entree API (provision.php)
                -run une seule fois pour provisionner les demandes valides
                lance provision.sh qui lui lance les scripts de provisionnement systeme

---------------------
[] VirutalHost :
    lancer serveur.sh  serveur 127.0.0.1
    test ordi client.sh  client 

    //ajouter sous domaine user.sh username ip

[]Dovecot ;
    lancer serveur.sh  serveur
[]Samba :
    lancer run.sh 

-------------------
Interface :
    - index.php : page d'accueil
    - connexion.php : page de connexion
    - modele.php : page de formulaire de demande
    - admin.php : interface admin pour valider les demandes
    - provision.php : script pour provisionner les demandes validées

-------------------
Repartition des taches (independantes)
| Nom                            | Rôle                  | Tâches principales                                                                                                                                                                 |
| ------------------------------ | --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Sarobidy**                   | Admin Réseau / BDD    | - Configurer BIND / DNS local<br>- Ajouter des utilisateurs et IP via `user.sh`<br>- Vérifier que chaque client a accès aux services réseau                                        |
| **Yoan**                       | Développeur Front-end | - Pages PHP dans `/Bubble/public` (connexion, index, formulaire)<br>- Validation côté client<br>- Intégration design HTML/CSS/JS                                                   |
| **Mendrika**                   | Développeur Back-end  | - Scripts PHP `/Bubble/core` (auth, logger, validator)<br>- API `/Bubble/api/provision.php`<br>- Gestion des sessions, sécurité, logs                                              |
| **Toi /Tsoa/ Programmateur Réseau** | Intégrateur / DevOps  | - Samba shares `/Samba` pour collaboration<br>- Postfix/Dovecot maildir vérification<br>- VirtualHost Apache `/VirtualHost`<br>- Gestion SSL, scripts `install.sh`, `provision.sh` |



[ ]-mail :interface :
	[]Boite mail :
		liste  message :
			[] lu
			[] non lu  
		
		Message :
			[ ] envoyeur 
			[ ] receveur 
			[ ] date 
			[ ] contenu 
			
			
		[] Message :
			ip :serveur :
			bubble.mg 
			
			DAte : jour ,11 Annee hh:min:ss 
			
			To :receiver@bubble.mg
			
			From :sender@bubble.mg
			
			Subject: jgjkvkujg8ou
			
			Contenu : Coucou	


              ENVOI
PHP → Postfix (SMTP 25/587)
       ↓
DNS MX (bubble.mg)
       ↓
Serveur distant

              RÉCEPTION
Serveur distant
       ↓
Postfix (SMTP 25)
       ↓
Maildir (/home/user/Maildir)
       ↓
Dovecot (IMAP 143/993)
       ↓
PHP Webmail
		
			 




Maildir :
    /home/username/Maildir/
        cur/    # Messages lus
        new/    # Messages non lus
        tmp/    # Fichiers temporaires pendant la livraison

Reception mail :        
        entrant → Postfix -> home/username/Maildir→ Dovecot

Webmail roundcube
        IMAP : Dovecot (143/993) lit Maildir
        SMTP : Postfix (25/587) renvoye

## IMAP : Dovecot
        host : localhost 
        port 143 : 993 (SSL)
        user : username // nyavo@bubble.mg
        pass : password (linux)


## SMTPO :Posfix
        host : localhost
        port : 25 (non sécurisé) ou 587 (STARTTLS)
        user : username //
