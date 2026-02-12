#!/bin/bash
# Script pour exporter tous les fichiers de configuration vers un seul fichier texte.
# Usage : sudo ./export_config.sh [fichier_sortie]

OUTPUT="${1:-source.txt}"   # Nom du fichier de sortie (défaut : source_config.txt)

# Répertoires à parcourir
DIRS=(
    "/Bubble"
    "/Dovecot"
    "/Samba"
    "/database"
    "/VirtualHost"

)

# Vider/Créer le fichier de sortie
> "$OUTPUT"html/

echo "Export en cours vers $OUTPUT ..."

for dir in "${DIRS[@]}"; do
    if [[ ! -d "$dir" ]]; then
        echo "Répertoire introuvable : $dir" >> "$OUTPUT"
        continue
    fi

    find "$dir" -type f -print0 2>/dev/null | while IFS= read -r -d '' fichier; do
        # Écrire l'en-tête du fichier
        echo -e "\n\n===== $fichier =====\n" >> "$OUTPUT"

        # Tenter d'afficher le contenu ; s'il est binaire ou inaccessible, message d'erreur
        if file -b --mime "$fichier" | grep -q "^text/"; then
            cat "$fichier" 2>/dev/null >> "$OUTPUT" || echo "[ERREUR LECTURE]" >> "$OUTPUT"
        else
            echo "[FICHIER BINAIRE - contenu non affiché]" >> "$OUTPUT"
        fi
    done
done

echo "Export terminé. Résultat : $OUTPUT"