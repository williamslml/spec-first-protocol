#!/bin/sh
# sfp-section.sh — imprime UNA sección del texto completo de SFP, para no cargar el archivo entero.
# Uso: sh sfp-section.sh <con|sin> <número>     ej.: sh sfp-section.sh sin 9.4   ·   sh sfp-section.sh con 7
# Un número de sección (7) incluye sus subsecciones (7.1…); uno de subsección (7.1) solo esa.
# Qué número leer para cada pregunta: references/sfp-index.md. Solo lectura.
# Códigos: 0 ok · 1 la sección no existe · 2 uso inválido.
set -u
case "${1:-}" in
  con) F=sfp-con-orquestador.md ;;
  sin) F=sfp-sin-orquestador.md ;;
  -h|--help|*) sed -n '2,6p' "$0"; [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] && exit 0; exit 2 ;;
esac
N=${2:-}
case "$N" in ''|*[!0-9.]*|.*|*.) sed -n '2,6p' "$0"; exit 2 ;; esac
SCRIPT_DIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd)
awk -v n="$N" '
  BEGIN { lvl = (index(n, ".") ? 3 : 2); pre = (lvl == 3 ? "### " : "## ") n (lvl == 3 ? " " : ". ") }
  /^###? / {   # sin {2,3}: mawk (awk por defecto en Debian/Ubuntu) no admite repeticiones con llaves
    h = match($0, /^#+/); hl = RLENGTH
    if (on && hl <= lvl) exit
    if (index($0, pre) == 1) { on = 1; found = 1 }
  }
  on { print }
  END { exit found ? 0 : 1 }' "$SCRIPT_DIR/../references/$F"
