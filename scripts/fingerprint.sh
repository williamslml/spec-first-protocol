#!/bin/sh
# fingerprint.sh — huellas sha256 de las acciones del manifiesto, sin copiarlas a mano.
# Uso:
#   sh fingerprint.sh [ruta]                      mide y muestra (SOLO LECTURA)
#   sh fingerprint.sh --propose [--refresh 3,5] [ruta]
#        escribe .sfp/manifest.proposed.json con actions[].sha256 completado y, en configure
#        con format json, actions[].changes calculado contra backup.ref. No toca el manifiesto.
#        Una huella ya registrada que difiere NO se cambia salvo los ids de --refresh (solo si el
#        usuario confirma que el contenido actual es el que dejó el setup).
#   sh fingerprint.sh --accept [ruta]
#        tras la aprobación del usuario: reemplaza el manifiesto por la propuesta, solo si valida
#        contra references/manifest.schema.json y sus huellas siguen coincidiendo con el proyecto.
# Cuándo: al terminar la Fase 6 (y en el modo Actualización, para instalaciones sin huellas).
# Qué se mide: create → el archivo; merge (y configure con markers) → solo el bloque entre
# sfp:start id=<id> y su end; dirs, move y configure json → sin huella ("-").
# Salida de la medición: "id<TAB>tipo<TAB>ruta<TAB>sha256|-".
# Códigos: 0 ok · 1 alguna acción no se pudo medir o la propuesta/aceptación falló ·
#          2 uso/ruta inválida · 3 falta jq/Python 3 o herramienta de sha256
#          (--propose y --accept requieren Python 3).

set -u
PROJECT="."
MODE=measure
REFRESH=""
while [ $# -gt 0 ]; do
  case "$1" in
    --propose) MODE=propose ;;
    --accept) MODE=accept ;;
    --refresh) shift; REFRESH="${1:-}" ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    -*) echo "ERROR: opción desconocida: $1" >&2; exit 2 ;;
    *) PROJECT="$1" ;;
  esac
  shift
done
[ -d "$PROJECT" ] || { echo "ERROR: no existe el directorio: $PROJECT" >&2; exit 2; }
SCRIPT_DIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd)
# shellcheck source=lib.sh
. "$SCRIPT_DIR/lib.sh"
cd "$PROJECT" || exit 2
[ -f "$MANIFEST" ] || { echo "ERROR: no existe $MANIFEST" >&2; exit 2; }
[ -n "$JSON_TOOL" ] || { echo "INCOMPLETO: ni jq ni Python 3 disponibles" >&2; exit 3; }
have_sha256 || { echo "INCOMPLETO: sin sha256sum/shasum/openssl/Python 3" >&2; exit 3; }
if [ "$MODE" != measure ] && [ -z "$PY" ]; then
  echo "INCOMPLETO: --propose y --accept necesitan Python 3 (python3 o python)" >&2; exit 3
fi

OUT=$(actions_tsv | while IFS="$TAB" read -r id type path from markers sha fmt; do
  [ -z "$type" ] && continue
  if ! safe_path "$path"; then
    printf '%s\t%s\t%s\t%s\n' "$id" "$type" "$path" "- (ruta inválida)"
    continue
  fi
  case "$type" in
    create)
      if [ -d "$path" ]; then H="-"; else H=$(fingerprint "$type" "$path" "$markers" "$id"); H=${H:-"- (no existe)"}; fi ;;
    configure)
      if [ "$fmt" = "json" ]; then H="-"
      elif [ "$markers" != "true" ]; then H=$(fingerprint "$type" "$path" "$markers" "$id")
      elif [ -f "$path" ] && block_content "$path" "$id" >/dev/null; then H=$(fingerprint "$type" "$path" "$markers" "$id")
      else H="- (bloque id=$id no encontrado)"; fi
      H=${H:-"- (no existe)"} ;;
    merge)
      if [ -f "$path" ] && block_content "$path" "$id" >/dev/null; then
        H=$(fingerprint "$type" "$path" "$markers" "$id")
      else
        H="- (bloque id=$id no encontrado)"
      fi
      H=${H:-"- (no existe)"} ;;
    *) H="-" ;;
  esac
  printf '%s\t%s\t%s\t%s\n' "$id" "$type" "$path" "$H"
done)

PROPOSED=".sfp/manifest.proposed.json"
case "$MODE" in
  measure)
    [ -n "$OUT" ] && printf '%s\n' "$OUT"
    case "$OUT" in *"$TAB- ("*) exit 1 ;; esac
    exit 0 ;;
  propose|accept)
    TSV=$(mktemp 2>/dev/null || echo "${TMPDIR:-/tmp}/fingerprint.$$")
    trap 'rm -f "$TSV"' EXIT
    printf '%s\n' "$OUT" > "$TSV"
    if [ "$MODE" = propose ]; then
      if [ -n "$REFRESH" ]; then manifest_tool propose "$MANIFEST" "$TSV" "$PROPOSED" --refresh "$REFRESH"
      else manifest_tool propose "$MANIFEST" "$TSV" "$PROPOSED"; fi
      RC=$?
      echo "validación de la propuesta:"
      manifest_tool check "$PROPOSED" | sed 's/^/  /'
      exit $RC
    else
      manifest_tool accept "$MANIFEST" "$PROPOSED" "$TSV"
      exit $?
    fi ;;
esac
