<?php
// Roundcube config bridge for Bubble.mg
// Import IMAP/SMTP templates and map to Roundcube config format.

$imap = require __DIR__ . '/roundcube-imap.php';
$smtp = require __DIR__ . '/roundcube-smtp.php';

// IMAP settings
$config['default_host'] = $imap['default_host'];
$config['default_port'] = $imap['default_port'];

if (!empty($imap['imap_ssl'])) {
    $config['imap_conn_options'] = [
        'ssl' => [
            'verify_peer' => false,
            'verify_peer_name' => false,
            'allow_self_signed' => true,
        ],
    ];
}

if (!empty($imap['mail_domain'])) {
    $config['mail_domain'] = $imap['mail_domain'];
}

// SMTP settings
$config['smtp_server'] = $smtp['smtp_server'];
$config['smtp_port'] = $smtp['smtp_port'];
$config['smtp_user'] = $smtp['smtp_user'];
$config['smtp_pass'] = $smtp['smtp_pass'];

if (!empty($smtp['smtp_secure'])) {
    $config['smtp_secure'] = $smtp['smtp_secure'];
}

if (!empty($smtp['smtp_auth_type'])) {
    $config['smtp_auth_type'] = $smtp['smtp_auth_type'];
}

if (!empty($smtp['smtp_helo_host'])) {
    $config['smtp_helo_host'] = $smtp['smtp_helo_host'];
}

// General
$config['product_name'] = 'Bubble.mg Webmail';
$config['support_url'] = '';
