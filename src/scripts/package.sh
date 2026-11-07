#!/usr/bin/env bash
# ============================================================================
# Genera el ZIP de entrega.
#
#   ./src/scripts/package.sh
#   INCLUDE_DATA=1 ./src/scripts/package.sh   # incluye los CSV (no los pósters)
#
# El PDF del informe debe compilarse antes con:
#   latexmk -pdf -outdir=docs/build docs/informe.tex
# ============================================================================

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "$0")/../.." && pwd)"
cd "$ROOT"

OUT="${1:-$ROOT/trabajo_final.zip}"

if ! command -v zip >/dev/null 2>&1; then
    echo "Error: no se encontró 'zip'." >&2
    exit 1
fi

rm -f "$OUT"

FILES=(
    README.md
    src
    docs/informe.tex
    docs/trabajo_final_2026.tex
    extra
)

if [[ -f docs/build/informe.pdf ]]; then
    FILES+=("docs/build/informe.pdf")
else
    echo "Aviso: no existe docs/build/informe.pdf; se omite el PDF." >&2
fi

if [[ "${INCLUDE_DATA:-0}" == "1" ]]; then
    FILES+=(data/*.csv)
else
    echo "Aviso: los CSV no se incluyen. Usa INCLUDE_DATA=1 para agregarlos." >&2
fi

zip -r "$OUT" "${FILES[@]}" \
    -x 'docs/build/*.aux' 'docs/build/*.log' 'docs/build/*.out' \
       'docs/build/*.toc' 'docs/build/*.fls' 'docs/build/*.fdb_latexmk'

echo "Listo: $OUT"
