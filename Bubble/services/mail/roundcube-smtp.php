<?php
// Roundcube SMTP settings (template)
return [
    // SMTP server (Postfix)
    'smtp_server' => 'localhost',
    'smtp_port' => 25,

    // Use the same credentials as IMAP
    'smtp_user' => '%u',
    'smtp_pass' => '%p',

    // Optional: set to 'ssl' and 465 or 'tls' and 587 when TLS is enabled
    'smtp_secure' => null,
    'smtp_auth_type' => 'LOGIN',

    // Helo/hostname for SMTP
    'smtp_helo_host' => 'bubble.mg',
];
