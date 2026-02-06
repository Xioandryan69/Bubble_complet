<?php 
$username = escapeshellarg($username);
$ip = escapeshellarg($ip);

exec("/usr/local/bin/provision.sh $username $ip");
