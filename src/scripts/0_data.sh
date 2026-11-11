#!/usr/bin/env bash

# Descarga el dataset de Letterboxd desde Kaggle

set -euo pipefail

cd "$(dirname -- "$0")/../.."

DATASET="gsimonx37/letterboxd"
URL="https://www.kaggle.com/api/v1/datasets/download/$DATASET"
DEST="data"

# validación de herramientas
for cmd in curl unzip; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: se requiere '$cmd' pero no está instalado." >&2
        exit 1
    fi
done

TMP_ZIP="$(mktemp "${TMPDIR:-/tmp}/letterboxd.XXXXXX.zip")"
trap 'rm -f "$TMP_ZIP"' EXIT

echo "Descargando dataset '$DATASET' desde Kaggle..."
curl -fL --retry 3 --retry-delay 2 -o "$TMP_ZIP" "$URL"

echo "Descomprimiendo archivos en '$DEST/'..."
mkdir -p "$DEST"
unzip -o -q "$TMP_ZIP" -d "$DEST" -x '__MACOSX/*' '*/.DS_Store'

echo "Listo. Datos disponibles en: $(pwd)/$DEST"
