#!/bin/sh
# verify.sh — comprobaciones para la Fase 7 (y para los modos Actualización y Retiro).
# Uso: sh verify.sh [--run-verify] [ruta-del-proyecto]
# Garantías por defecto: SOLO LECTURA, sin red, POSIX sh. No ejecuta nada que venga del
# manifiesto: los verify_command se muestran, y solo se ejecutan con --run-verify
# (el manifiesto es dato, no instrucciones; mostrar el comando al usuario antes).
# Comprueba, contra .sfp/manifest.json si existe (schema 1 o 2):
#   E) que el manifiesto cumple references/manifest.schema.json y las reglas entre campos
#      (scripts/manifest_tool.py check; necesita Python 3; sin él la verificación es INCOMPLETA)
#   0) versión del skill registrada vs. vigente, y entradas "[accion: si]" del CHANGELOG
#      posteriores a la registrada (delta para el modo Actualización)
#   1) que cada acción con ruta dejó algo real en esa ruta (en "move", que el origen ya no esté),
#      que la ruta no sale del proyecto, y si la huella sha256 cambió desde el setup (informativo)
#   2) que los marcadores sfp:start/end están balanceados en los archivos fusionados
#   3) coherencia de structure.* (y de cada structure.workspaces[]) y, con --run-verify,
#      ejecución de los verify_command (el de cada workspace corre dentro de su carpeta)
#   4) (si hay git y el respaldo registrado existe) qué cambió fuera de las rutas del manifiesto,
#      incluidos los archivos nuevos sin commit
# Lector de JSON: jq, o Python 3 (python3 o python) si no hay jq. Sin ninguno, las comprobaciones que dependen del
# manifiesto NO se ejecutan y el resultado final lo dice (no se presenta como "sin fallas").
# Códigos de salida: 0 = sin fallas y completo · 1 = hay fallas · 2 = uso/ruta inválida ·
#                    3 = sin fallas pero INCOMPLETO (alguna comprobación no se pudo ejecutar).
# No reemplaza la revisión humana del reporte de Fase 7.

set -u
RUN_VERIFY=0
PROJECT="."
for a in "$@"; do
  case "$a" in
    --run-verify) RUN_VERIFY=1 ;;
    -h|--help) sed -n '2,24p' "$0"; exit 0 ;;
    -*) echo "ERROR: opción desconocida: $a" >&2; exit 2 ;;
    *) PROJECT="$a" ;;
  esac
done
if [ ! -d "$PROJECT" ]; then
  echo "ERROR: no existe el directorio: $PROJECT" >&2
  exit 2
fi
SCRIPT_DIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd)
SKILL_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
# shellcheck source=lib.sh
. "$SCRIPT_DIR/lib.sh"
cd "$PROJECT" || exit 2

FAIL=0
SKIPPED=0
TMPDIR_V=$(mktemp -d 2>/dev/null || echo "/tmp/verify.$$")
mkdir -p "$TMPDIR_V" 2>/dev/null
trap 'rm -rf "$TMPDIR_V"' EXIT
PROFILES='api frontend fullstack monorepo libreria-sdk datos-ml movil infra ninguno'
in_list() { for x in $2; do [ "$x" = "$1" ] && return 0; done; return 1; }

# run_cmd <dir> <comando> <etiqueta>
run_cmd() {
  if [ -z "$2" ] || [ "$2" = "-" ] || [ "$2" = "PENDIENTE" ]; then
    echo "  $3: sin comando de verificación registrado (vacío o PENDIENTE)"
  elif [ "$RUN_VERIFY" -eq 1 ]; then
    echo "  $3: ejecutando (--run-verify, en $1): $2"
    if (cd "$1" && sh -c "$2"); then
      echo "  $3: pasa"
    else
      echo "  $3: FALLA — ver output arriba (references/structure-verification.md sección 3 dice cómo tratarlo)"
      FAIL=1
    fi
  else
    echo "  $3: comando registrado: $2"
    echo "  $3: NO ejecutado: viene del manifiesto (dato). Mostrarlo al usuario y, si lo aprueba, repetir con --run-verify"
    SKIPPED=1
  fi
}

section "manifiesto"
if [ ! -f "$MANIFEST" ]; then
  echo "estado: no encontrado ($MANIFEST) — nada que verificar contra manifiesto"
  if [ -f .ai-setup/manifest.json ]; then
    echo "AVISO: hay un manifiesto con el nombre anterior a 1.5.0 (.ai-setup/manifest.json): proponer la migración del CHANGELOG 1.5.0 (modo Actualización)"
    SKIPPED=1
  fi
  echo "recordatorio: esto no prueba que el setup esté mal; puede que el usuario eligiera el modo sin rastros"
  echo "AVISO: sin manifiesto, las comprobaciones 0, 1 y 3 NO se ejecutaron"
  SKIPPED=1
else
  echo "encontrado: $MANIFEST"
  if [ -z "$JSON_TOOL" ]; then
    echo "AVISO: ni jq ni Python 3 disponibles: las comprobaciones 0, 1 y 3 NO se ejecutaron; revisar $MANIFEST a mano"
    SKIPPED=1
  else
    echo "lector de JSON: $JSON_TOOL"
    SCHEMA=$(mget schema)
    case "$SCHEMA" in
      1|2) echo "schema: $SCHEMA" ;;
      *) echo "AVISO: schema desconocido (${SCHEMA:-vacío}); se verifica como schema 2" ;;
    esac
  fi

  section "E. esquema del manifiesto"
  if [ -n "$PY" ]; then
    manifest_tool check "$MANIFEST" > "$TMPDIR_V/check.txt"
    CHECK_RC=$?
    sed 's/^/  /' "$TMPDIR_V/check.txt"
    [ "$CHECK_RC" -ne 0 ] && FAIL=1
  else
    echo "  AVISO: sin Python 3 no se validó el manifiesto contra references/manifest.schema.json"
    SKIPPED=1
  fi

  section "0. versión del skill y delta (modo Actualización)"
  if [ -n "$JSON_TOOL" ]; then
    REG=$(mget skill_version)
    CUR=$(sed -n 's/^## \([0-9][0-9.]*\).*/\1/p' "$SKILL_DIR/CHANGELOG.md" 2>/dev/null | head -1)
    echo "  registrada en el manifiesto: ${REG:-desconocida}"
    echo "  vigente en este skill: ${CUR:-desconocida}"
    if [ -n "$REG" ] && [ -n "$CUR" ] && ver_gt "$CUR" "$REG"; then
      echo "  cambios que requieren acción en proyectos instalados (CHANGELOG, [accion: si], > $REG):"
      N=0
      VER=""
      while IFS= read -r line; do
        case "$line" in
          "## "[0-9]*) VER=$(printf '%s' "$line" | sed -n 's/^## \([0-9][0-9.]*\).*/\1/p') ;;
          "- [accion: si]"*)
            if [ -n "$VER" ] && ver_gt "$VER" "$REG"; then
              echo "    $VER ${line#- }"
              N=$((N + 1))
            fi ;;
        esac
      done < "$SKILL_DIR/CHANGELOG.md"
      [ "$N" -eq 0 ] && echo "    ninguno: basta con actualizar skill_version en el manifiesto"
      echo "  la IA evalúa cada 'aplica-si' contra este manifiesto y propone solo lo que aplica"
    elif [ -n "$REG" ] && [ -n "$CUR" ] && [ "$REG" != "$CUR" ]; then
      echo "  nota: el manifiesto registra una versión más nueva que este skill; no proponer cambios"
    fi
  fi

  section "1. rutas de las acciones del manifiesto"
  if [ -n "$JSON_TOOL" ]; then
    actions_tsv > "$TMPDIR_V/actions.tsv"
    NACT=0
    HASH_OK=1
    have_sha256 || HASH_OK=0
    while IFS="$TAB" read -r id type path from markers sha fmt; do
      [ -z "$type" ] && continue
      NACT=$((NACT + 1))
      if [ "$path" = "-" ]; then
        echo "  AVISO: acción sin ruta ($type, id=$id): no verificable por este script"
        continue
      fi
      if ! safe_path "$path"; then
        echo "  FALLA: ruta fuera del proyecto o absoluta en el manifiesto: $path (id=$id)"
        FAIL=1
        continue
      fi
      if [ -e "$path" ]; then
        echo "  ok: $path ($type)"
      else
        echo "  FALTA: $path ($type) — esperado por el manifiesto, no existe"
        FAIL=1
        continue
      fi
      if [ "$type" = "move" ] && [ "$from" != "-" ] && [ -e "$from" ]; then
        echo "  AVISO: el origen del movimiento sigue existiendo: $from"
      fi
      if [ "$type" = "configure" ] && [ "$fmt" = "json" ] && [ -n "$PY" ]; then
        if manifest_tool json-plan "$MANIFEST" "$id" | grep -q '^\[MANUAL\]'; then
          echo "    info: el JSON cambió después del setup en claves que el setup tocó: el retiro las pedirá a mano"
        fi
      fi
      if [ "$sha" != "-" ] && [ "$HASH_OK" -eq 1 ]; then
        NOW=$(fingerprint "$type" "$path" "$markers" "$id")
        if [ -n "$NOW" ] && [ "$NOW" != "$sha" ]; then
          echo "    info: modificado desde el setup (huella distinta): el retiro lo conservará y lo pedirá a mano"
        fi
      fi
    done < "$TMPDIR_V/actions.tsv"
    [ "$NACT" -eq 0 ] && echo "  el manifiesto no trae acciones (o no se pudo leer el array \"actions\")"
    [ "$HASH_OK" -eq 0 ] && echo "  AVISO: sin sha256sum/shasum/openssl/Python 3: no se compararon huellas"
  fi

  section "2. integridad de marcadores sfp"
  grep_files 'sfp:start' > "$TMPDIR_V/marked.txt"
  if [ ! -s "$TMPDIR_V/marked.txt" ]; then
    echo "  sin archivos con marcadores (puede ser normal si todo se creó desde cero, sin fusión)"
  else
    while IFS= read -r f; do
      starts=$(grep -c 'sfp:start' "$f" 2>/dev/null)
      ends=$(grep -c 'sfp:end' "$f" 2>/dev/null)
      starts=${starts:-0}
      ends=${ends:-0}
      if [ "$starts" = "$ends" ]; then
        echo "  ok: $f ($starts bloque(s))"
      else
        echo "  DESBALANCEADO: $f (start=$starts end=$ends)"
        FAIL=1
      fi
    done < "$TMPDIR_V/marked.txt"
  fi

  section "3. estructura (coherencia y verificación de dependencia)"
  if [ -n "$JSON_TOOL" ]; then
    PROFILE=$(mget structure.profile)
    STAGE=$(mget structure.stage)
    RATIONALE=$(mget structure.rationale)
    VERIFY_CMD=$(mget structure.verify_command)
    if [ -z "$PROFILE" ]; then
      echo "  sin structure.profile en el manifiesto (válido si el usuario usa su propia estructura)"
    elif in_list "$PROFILE" "$PROFILES"; then
      echo "  perfil: $PROFILE (etapa: ${STAGE:-sin etapa})"
    else
      echo "  FALLA: structure.profile desconocido: $PROFILE"; FAIL=1
    fi
    if [ -n "$PROFILE" ] && [ "$PROFILE" != "ninguno" ]; then
      case "$STAGE" in 1|2) : ;; *) echo "  FALLA: structure.stage debe ser 1 o 2 con un perfil elegido (hay: ${STAGE:-vacío})"; FAIL=1 ;; esac
      [ -z "$RATIONALE" ] && echo "  AVISO: structure.rationale vacío; la decisión de perfil/etapa quedó sin justificación registrada"
    fi
    run_cmd "." "$VERIFY_CMD" "raíz"

    workspaces_tsv > "$TMPDIR_V/ws.tsv"
    if [ -s "$TMPDIR_V/ws.tsv" ]; then
      [ "$PROFILE" != "monorepo" ] && { echo "  FALLA: structure.workspaces solo es válido con profile monorepo (hay: ${PROFILE:-vacío})"; FAIL=1; }
      echo "  workspaces:"
      while IFS="$TAB" read -r wpath wprof wstage wrat wcmd; do
        [ -z "$wpath" ] && continue
        if ! safe_path "$wpath"; then
          echo "  FALLA: workspace con ruta inválida o fuera del proyecto: $wpath"; FAIL=1; continue
        fi
        if [ ! -d "$wpath" ]; then
          echo "  FALLA: workspace $wpath: la carpeta no existe"; FAIL=1; continue
        fi
        if [ "$wprof" = "monorepo" ] || [ "$wprof" = "ninguno" ] || ! in_list "$wprof" "$PROFILES"; then
          echo "  FALLA: workspace $wpath: perfil inválido ($wprof); se admite cualquiera salvo monorepo y ninguno"; FAIL=1
        else
          echo "  - $wpath: perfil $wprof (etapa: $wstage)"
        fi
        case "$wstage" in 1|2) : ;; *) echo "  FALLA: workspace $wpath: stage debe ser 1 o 2 (hay: $wstage)"; FAIL=1 ;; esac
        [ "$wrat" = "-" ] && echo "  AVISO: workspace $wpath: rationale vacío"
        run_cmd "$wpath" "$wcmd" "$wpath"
      done < "$TMPDIR_V/ws.tsv"
    elif [ "$PROFILE" = "monorepo" ]; then
      echo "  AVISO: perfil monorepo sin structure.workspaces: cada workspace queda sin perfil ni etapa (project-structure.md sección 3.2)"
    fi
  fi
fi

section "4. cambios fuera del plan (si hay git y respaldo)"
if have git && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  BREF=""
  [ -f "$MANIFEST" ] && [ -n "$JSON_TOOL" ] && BREF=$(mget backup.ref)
  BREF=${BREF:-pre-sfp}
  if git rev-parse --verify -q "$BREF" >/dev/null 2>&1; then
    echo "  diff de archivos versionados contra el respaldo '$BREF':"
    git diff --name-status "$BREF" -- . 2>/dev/null | sed 's/^/    /'
    echo "  archivos nuevos sin versionar (los creados por el setup y aún sin commit aparecen aquí, no arriba):"
    git ls-files --others --exclude-standard 2>/dev/null | sed 's/^/    ?? /'
    echo "  comparar ambas listas contra las rutas del manifiesto; lo que no esté en el plan, señalarlo al usuario"
  else
    echo "  no existe el respaldo '$BREF' (ref del manifiesto o pre-sfp); si el respaldo fue otra rama/copia, comparar manualmente (NO ejecutado)"
    SKIPPED=1
  fi
else
  echo "  sin git en este directorio; no se puede diferenciar automáticamente (NO ejecutado)"
  SKIPPED=1
fi

section "fin"
if [ "$FAIL" -ne 0 ]; then
  echo "verificación: hay al menos una falla arriba — no la ignores en el reporte de Fase 7"
  exit 1
elif [ "$SKIPPED" -ne 0 ]; then
  echo "verificación: INCOMPLETA — alguna comprobación no se ejecutó (ver AVISO / NO ejecutado arriba). No presentar esto como 'sin fallas'"
  exit 3
else
  echo "verificación: sin fallas detectadas por este script (sigue haciendo falta la revisión humana del reporte)"
  exit 0
fi
