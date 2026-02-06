#!/bin/bash

echo "=== DOVECOT STATUS ==="
sudo systemctl status dovecot --no-pager

echo -e "\n=== DOVECOT CONFIGURATION (doveconf -n) ==="
sudo doveconf -n

echo -e "\n=== DOVECOT LISTENING PORTS ==="
sudo ss -tlnp | grep dovecot

echo -e "\n=== DOVECOT LOGS (last 10 lines) ==="
sudo tail -10 /var/log/dovecot.log 2>/dev/null || echo "Log file not found, trying journal..."
sudo journalctl -u dovecot --no-pager -n 10

echo -e "\n=== DOVECOT PROCESSES ==="
ps aux | grep dovecot
