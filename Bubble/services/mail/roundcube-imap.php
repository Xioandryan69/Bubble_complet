<?php
// Roundcube IMAP settings (template)
return [
    // IMAP server (Dovecot)
    'default_host' => 'localhost',
    'default_port' => 143,

    // Optional: set to 'ssl' and 993 when TLS is enabled in Dovecot
    'imap_ssl' => false,

    // Domain appended when user logs in without @domain
    'mail_domain' => 'bubble.mg',
];
