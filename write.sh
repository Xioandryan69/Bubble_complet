#!/bin/bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
output_file="$(cd "${root_dir}/.." && pwd)/source.txt"

> "$output_file"

while IFS= read -r -d '' file; do
  rel_path="${file#"$root_dir"/}"
  {
    printf '=== %s ===\n' "$rel_path"
    cat "$file"
    printf '\n\n'
  } >> "$output_file"
done < <(find "$root_dir" -type f -print0 | sort -z)
