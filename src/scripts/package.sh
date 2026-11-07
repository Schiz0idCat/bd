#!/usr/bin/env bash
# ============================================================================
# ETAPA 5: genera el ZIP de entrega.
#
#   ./src/scripts/package.sh
# ============================================================================

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "$0")/../.." && pwd)"
cd "$ROOT"

OUT="$ROOT/trabajo_final.zip"

if ! command -v zip >/dev/null 2>&1; then
    echo "Error: no se encontró 'zip'." >&2
    exit 1
fi

if [[ ! -f docs/informe.pdf ]]; then
    echo "Error: no existe docs/informe.pdf." >&2
    echo "Compila el informe antes de empaquetar." >&2
    exit 1
fi

rm -f "$OUT"

FILES=(
    README.md
    src
    docs/informe.tex
    docs/informe.pdf
    docs/trabajo_final_2026.tex
    extra
)

zip -r "$OUT" "${FILES[@]}"

echo "Listo: $OUT"
