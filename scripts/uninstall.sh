#!/bin/sh
# uninstall.sh — retiro de lo que instaló spec-first-protocol, a partir del manifiesto y los marcadores.
# Uso: sh uninstall.sh [--apply] [ruta-del-proyecto]
# Por defecto es DRY-RUN: no escribe nada; imprime el plan de retiro clasificado:
#   [AUTO]   se puede retirar solo: sin cambios desde el setup (huella sha256 igual) o enlace creado
#   [MANUAL] lo decide el usuario: editado después del setup, sin huella, move, configure sin marcadores
#            (un configure con format json se revierte clave por clave con sus "changes":
#            solo las claves que siguen como las dejó el setup son [AUTO]; necesita Python 3)
#   [INFO]   nada que hacer (ya no existe, bloque ya retirado)
#   [ERROR]  ruta inválida o fuera del proyecto, marcadores desbalanceados, fallo al aplicar
# --apply ejecuta SOLO los [AUTO]. Nunca toca un [MANUAL]: para esos imprime el comando exacto
# que el usuario puede aprobar. Nunca hace commit, push ni reset.
# Orden: archivos y bloques por id descendente (lo último instalado se retira primero); luego
# carpetas creadas, de la más profunda a la menos, y solo si quedan vacías; al final el
# manifiesto (.sfp/), y solo si no queda nada pendiente. Repetirlo es seguro (idempotente).
# Códigos: 0 nada pendiente · 1 algún [ERROR] · 2 uso/ruta inválida ·
#          3 quedan [MANUAL] (o no se pudo leer el manifiesto).
# Procedimiento completo con el usuario: references/uninstall.md.

set -u
APPLY=0
PROJECT="."
for a in "$@"; do
  case "$a" in
    --apply) APPLY=1 ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    -*) echo "ERROR: opción desconocida: $a" >&2; exit 2 ;;
    *) PROJECT="$a" ;;
  esac
done
[ -d "$PROJECT" ] || { echo "ERROR: no existe el directorio: $PROJECT" >&2; exit 2; }
SCRIPT_DIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd)
# shellcheck source=lib.sh
. "$SCRIPT_DIR/lib.sh"
cd "$PROJECT" || exit 2

NAUTO=0; NMAN=0; NERR=0
DEL_LIST=""
DIR_LIST=""
auto()   { NAUTO=$((NAUTO + 1)); echo "[AUTO]   $*"; }
manual() { NMAN=$((NMAN + 1));  echo "[MANUAL] $*"; }
info()   { echo "[INFO]   $*"; }
err()    { NERR=$((NERR + 1));  echo "[ERROR]  $*"; }
done_()  { echo "[HECHO]  $*"; }
norm()   { _p=${1#./}; _p=${_p%/}; printf '%s' "$_p"; }
q()      { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"; }

echo "# Retiro — spec-first-protocol ($( [ "$APPLY" -eq 1 ] && echo APLICANDO || echo DRY-RUN: no se modifica nada))"
if [ ! -f "$MANIFEST" ]; then
  echo "No hay $MANIFEST: sin manifiesto el retiro es manual (buscar marcadores sfp:start con discover.sh, sección setup-previo)."
  exit 3
fi
if [ -z "$JSON_TOOL" ]; then
  echo "INCOMPLETO: ni jq ni Python 3 disponibles; leer $MANIFEST a mano y seguir references/uninstall.md."
  exit 3
fi
HASH_OK=1; have_sha256 || HASH_OK=0
[ "$HASH_OK" -eq 0 ] && echo "AVISO: sin herramienta sha256: ningún archivo se puede comprobar, todo queda [MANUAL]"
BREF=$(mget backup.ref); BREF=${BREF:-pre-sfp}

if have git && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  DIRTY=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  echo "git: $DIRTY cambio(s) sin commitear. Antes de --apply, proponer al usuario un punto de retorno (commit o tag pre-sfp-uninstall)."
fi

# compara la huella registrada con la actual → auto | modificado | sin-huella
hash_state() { # $1 tipo $2 ruta $3 markers $4 id $5 sha-registrado
  [ "$5" = "-" ] && { echo sin-huella; return; }
  [ "$HASH_OK" -eq 1 ] || { echo sin-huella; return; }
  _now=$(fingerprint "$1" "$2" "$3" "$4")
  [ "$_now" = "$5" ] && echo auto || echo modificado
}

ACTS=$(actions_tsv | sort -t "$TAB" -k1,1nr)
echo
echo "## Archivos y bloques (id descendente)"
while IFS="$TAB" read -r id type path from markers sha fmt; do
  [ -z "$type" ] && continue
  if [ "$path" = "-" ]; then manual "acción id=$id ($type) sin ruta: revisar a mano con su 'note'"; continue; fi
  if ! safe_path "$path"; then err "id=$id: ruta inválida o fuera del proyecto en el manifiesto, no se toca: $path"; continue; fi
  path=$(norm "$path")
  case "$type" in
    move)
      manual "id=$id move: $path ← $( [ "$from" = "-" ] && echo '(origen desconocido)' || echo "$from"). Revertir a mano: git mv $(q "$path") $(q "$from"), más imports/config que cambiaron con él; preferible revertir los commits de la reestructuración o volver al respaldo '$BREF'"
      ;;
    create)
      if [ -L "$path" ]; then
        auto "id=$id BORRAR enlace: $path"
        DEL_LIST="$DEL_LIST
$path"
        if [ "$APPLY" -eq 1 ]; then rm -f -- "$path" && done_ "borrado enlace $path" || err "no se pudo borrar $path"; fi
      elif [ -d "$path" ]; then
        DIR_LIST="$DIR_LIST
$path"
      elif [ ! -e "$path" ]; then
        info "id=$id ya no existe: $path"
      else
        case $(hash_state create "$path" "$markers" "$id" "$sha") in
          auto)
            auto "id=$id BORRAR archivo (sin cambios desde el setup): $path"
            DEL_LIST="$DEL_LIST
$path"
            if [ "$APPLY" -eq 1 ]; then rm -f -- "$path" && done_ "borrado $path" || err "no se pudo borrar $path"; fi ;;
          modificado)
            manual "id=$id $path fue EDITADO después del setup: se conserva. Opciones para el usuario: conservarlo (queda como archivo suyo), o borrarlo tras revisarlo: rm -- $(q "$path")" ;;
          *)
            manual "id=$id $path no tiene huella (manifiesto anterior a 1.3.0 o sin sha256): no se sabe si se editó. Revisarlo con el usuario; borrar solo con su aprobación: rm -- $(q "$path")" ;;
        esac
      fi
      ;;
    merge|configure)
      if [ "$type" = "configure" ] && [ "$fmt" = "json" ]; then
        if [ -z "$PY" ]; then
          manual "id=$id configure json en $path: sin Python 3 no se puede comparar clave por clave; revertir a mano con sus 'changes'"
          continue
        fi
        if [ "$APPLY" -eq 1 ]; then JOUT=$(manifest_tool json-plan "$MANIFEST" "$id" --apply)
        else JOUT=$(manifest_tool json-plan "$MANIFEST" "$id"); fi
        printf '%s\n' "$JOUT" | grep -v '^RESUMEN '
        SUM=$(printf '%s\n' "$JOUT" | sed -n 's/^RESUMEN auto=\([0-9]*\) manual=\([0-9]*\) error=\([0-9]*\)$/\1 \2 \3/p')
        set -- $SUM
        NAUTO=$((NAUTO + ${1:-0})); NMAN=$((NMAN + ${2:-0})); NERR=$((NERR + ${3:-0}))
        [ -z "$SUM" ] && err "id=$id no se pudo evaluar el JSON de $path"
        continue
      fi
      if [ "$type" = "configure" ] && [ "$markers" != "true" ]; then
        manual "id=$id configure sin marcadores en $path: revertir a mano según su 'note' (cambio de configuración: confirmación aparte)"
        continue
      fi
      if [ ! -f "$path" ]; then info "id=$id el archivo ya no existe: $path"; continue; fi
      S=$(grep -c 'sfp:start' "$path" 2>/dev/null); E=$(grep -c 'sfp:end' "$path" 2>/dev/null)
      if [ "${S:-0}" != "${E:-0}" ]; then err "id=$id marcadores desbalanceados en $path (start=$S end=$E): no se toca; corregir a mano"; continue; fi
      if ! block_content "$path" "$id" >/dev/null; then info "id=$id bloque no encontrado en $path (ya retirado o marcadores borrados a mano)"; continue; fi
      case $(hash_state "$type" "$path" "$markers" "$id" "$sha") in
        auto)
          auto "id=$id QUITAR bloque de $path (sin cambios desde el setup; el resto del archivo no se toca)"
          if [ "$APPLY" -eq 1 ]; then remove_block "$path" "$id" && done_ "quitado bloque id=$id de $path" || err "no se pudo editar $path"; fi ;;
        modificado)
          manual "id=$id el bloque de $path fue EDITADO después del setup: se conserva. Mostrar el bloque al usuario; si decide quitarlo, borrar las líneas entre los marcadores id=$id (incluidos)" ;;
        *)
          manual "id=$id el bloque de $path no tiene huella: mostrarlo al usuario y quitarlo solo con su aprobación" ;;
      esac
      ;;
    *)
      manual "id=$id tipo desconocido '$type' en $path: revisar a mano" ;;
  esac
done <<EOF
$ACTS
EOF

echo
echo "## Carpetas creadas (de la más profunda a la menos; solo si quedan vacías)"
DIRS_SORTED=$(printf '%s\n' "$DIR_LIST" | grep . | awk '{print length($0)"\t"$0}' | sort -t "$TAB" -k1,1nr | cut -f2-)
if [ -z "$DIRS_SORTED" ]; then echo "(ninguna)"; fi
while IFS= read -r d; do
  [ -z "$d" ] && continue
  REST=$(find "$d" -type f ! -name .gitkeep 2>/dev/null | sed 's#^\./##' | while IFS= read -r f; do
    printf '%s\n' "$DEL_LIST" | grep -qxF "$f" || echo "$f"
  done)
  if [ -n "$REST" ]; then
    N=$(printf '%s\n' "$REST" | grep -c .)
    manual "carpeta $d: quedarían $N archivo(s) que no son del setup o están pendientes (p. ej. $(printf '%s\n' "$REST" | head -1)): se conserva"
  else
    auto "BORRAR carpeta $d (queda vacía; incluye .gitkeep)"
    DEL_LIST="$DEL_LIST
$d"
    if [ "$APPLY" -eq 1 ]; then
      find "$d" -name .gitkeep -type f -exec rm -f {} \; 2>/dev/null
      find "$d" -depth -type d -empty -exec rmdir {} \; 2>/dev/null
      [ -e "$d" ] && err "no se pudo borrar la carpeta $d" || done_ "borrada carpeta $d"
    fi
  fi
done <<EOF
$DIRS_SORTED
EOF

echo
echo "## Manifiesto"
if [ "$NMAN" -eq 0 ] && [ "$NERR" -eq 0 ]; then
  OTHERS=$(find .sfp -type f ! -name manifest.json 2>/dev/null)
  if [ -n "$OTHERS" ]; then
    manual ".sfp/ contiene otros archivos (p. ej. $(printf '%s\n' "$OTHERS" | head -1)): borrar solo manifest.json y decidir el resto con el usuario"
    [ "$APPLY" -eq 1 ] && { rm -f .sfp/manifest.json && done_ "borrado .sfp/manifest.json"; }
  else
    auto "BORRAR .sfp/ (último paso: ya no queda nada instalado que dependa del manifiesto)"
    if [ "$APPLY" -eq 1 ]; then rm -f .sfp/manifest.json && rmdir .sfp 2>/dev/null && done_ "borrado .sfp/" || err "no se pudo borrar .sfp/"; fi
  fi
else
  info "se CONSERVA $MANIFEST: hace falta para los ítems [MANUAL]/[ERROR] pendientes (volver a ejecutar tras resolverlos)"
fi

echo
echo "## Resumen"
echo "auto: $NAUTO · manual: $NMAN · error: $NERR"
if [ "$APPLY" -eq 0 ]; then
  echo "DRY-RUN: nada fue modificado. Mostrar este plan al usuario; con su aprobación, repetir con --apply."
fi
if [ "$NERR" -gt 0 ]; then exit 1; fi
if [ "$NMAN" -gt 0 ]; then exit 3; fi
exit 0
