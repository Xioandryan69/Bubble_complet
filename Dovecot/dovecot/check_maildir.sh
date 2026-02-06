#!/bin/bash

echo "=== MAILDIR CHECK FOR USER $USER ==="
echo "Maildir path: ~/Maildir"

if [ -d ~/Maildir ]; then
    echo "Maildir exists."
    echo -e "\n=== STRUCTURE ==="
    find ~/Maildir -type d | sort
    echo -e "\n=== COUNTS ==="
    echo "Cur: $(find ~/Maildir/cur -type f 2>/dev/null | wc -l) emails"
    echo "New: $(find ~/Maildir/new -type f 2>/dev/null | wc -l) emails"
    echo "Tmp: $(find ~/Maildir/tmp -type f 2>/dev/null | wc -l) emails"
else
    echo "Maildir does not exist. Creating..."
    mkdir -p ~/Maildir/{cur,new,tmp}
    chmod -R 700 ~/Maildir
    echo "Created ~/Maildir with subdirectories cur, new, tmp."
fi

echo -e "\n=== PERMISSIONS ==="
ls -ld ~/Maildir
ls -ld ~/Maildir/* 2>/dev/null

echo -e "\n=== DOVECOT MAIL_LOCATION ==="
sudo doveconf -h mail_location 2>/dev/null

