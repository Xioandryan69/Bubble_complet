
#!/usr/bin/env bash
set -euo pipefail

USERNAME="$1"
IP="$2"

echo "[+] Provision user: $USERNAME"

# DNS + Mail + Web
/usr/local/bin/user.sh "$USERNAME" "$IP"

# Samba
/usr/local/bin/samba_add.sh "$USERNAME" "GROUP"

echo "[✓] Provision completed for $USERNAME"
