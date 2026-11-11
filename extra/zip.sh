#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT="${1:-$ROOT_DIR/trabajo_final.zip}"

rm -f "$OUTPUT"

cd "$ROOT_DIR"
zip -r "$OUTPUT" src docs/informe.pdf \
  -x '*.DS_Store' '*__pycache__*' '*/.*'

echo "Comprimido creado en: $OUTPUT"
