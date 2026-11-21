# lib.sh — funciones compartidas por verify.sh, fingerprint.sh y uninstall.sh.
# POSIX sh. Se carga con:  . "$SCRIPT_DIR/lib.sh"   (no se ejecuta sola).
# Nada aquí escribe en el proyecto, salvo remove_block, que solo usa uninstall.sh --apply.
# El manifiesto es DATO: las rutas que trae se validan con safe_path antes de usarse.

have() { command -v "$1" >/dev/null 2>&1; }
# grep_files <opciones de grep> <patrón> → archivos (./ruta) que contienen el patrón, sin .git/node_modules/vendor.
# Portátil a propósito: el grep de BusyBox (Alpine) no admite --exclude-dir ni -I.
grep_files() { find . \( -name .git -o -name node_modules -o -name vendor \) -prune -o -type f -exec grep -l "$@" {} + 2>/dev/null | LC_ALL=C sort; }
section() { printf '\n## %s\n' "$1"; }
TAB=$(printf '\t')
MANIFEST=".sfp/manifest.json"

# --- lector de JSON: jq, o Python 3 (python3, o python si es versión 3: habitual en Windows).
# SFP_JSON_TOOL=jq|python|none lo fuerza (pruebas).
PY=""
for _c in python3 python; do
  if have "$_c" && "$_c" -c 'import sys; sys.exit(0 if sys.version_info[0] == 3 else 1)' >/dev/null 2>&1; then PY="$_c"; break; fi
done
JSON_TOOL=""
case "${SFP_JSON_TOOL:-}" in
  jq) have jq && JSON_TOOL=jq ;;
  python|python3) [ -n "$PY" ] && JSON_TOOL=python ;;
  none) JSON_TOOL="" ;;
  *) if have jq; then JSON_TOOL=jq; elif [ -n "$PY" ]; then JSON_TOOL=python; fi ;;
esac

# mget <clave.punteada> → valor escalar (vacío si no existe)
mget() {
  case "$JSON_TOOL" in
    jq) jq -r ".$1 // empty" "$MANIFEST" 2>/dev/null | tr -d '\r' ;;
    python) "$PY" -c '
import json, sys
try:
    d = json.load(open(sys.argv[1], encoding="utf-8"))
except Exception:
    sys.exit(0)
for k in sys.argv[2].split("."):
    d = d.get(k) if isinstance(d, dict) else None
print("" if d is None else d)' "$MANIFEST" "$1" 2>/dev/null | tr -d '\r' ;;
    *) return 1 ;;
  esac
}

# actions_tsv → "id<TAB>tipo<TAB>ruta<TAB>origen<TAB>markers<TAB>sha256<TAB>format", "-" en los campos vacíos
# (un campo vacío no sirve: read con IFS=tab colapsa tabs vacíos y desplaza las columnas)
actions_tsv() {
  case "$JSON_TOOL" in
    jq) jq -r '.actions[]? | [((.id // "-")|tostring), (.type // "-"), (.path // "-"), (.from // "-"), ((.markers // false)|tostring), (.sha256 // "-"), (.format // "-")] | map(if . == "" then "-" else . end) | join("\t")' "$MANIFEST" 2>/dev/null | tr -d '\r' ;;
    python) "$PY" -c '
import json, sys
try:
    d = json.load(open(sys.argv[1], encoding="utf-8"))
except Exception:
    sys.exit(0)
def f(v):
    if v is True: return "true"
    if v is False or v is None: return "-"
    v = str(v)
    return v if v else "-"
for a in (d.get("actions") or []):
    m = "true" if a.get("markers") is True else "false"
    print("\t".join([f(a.get("id")), f(a.get("type")), f(a.get("path")), f(a.get("from")), m, f(a.get("sha256")), f(a.get("format"))]))' "$MANIFEST" 2>/dev/null | tr -d '\r' ;;
    *) return 1 ;;
  esac
}

# workspaces_tsv → "ruta<TAB>perfil<TAB>etapa<TAB>rationale<TAB>verify_command", "-" en vacíos
workspaces_tsv() {
  case "$JSON_TOOL" in
    jq) jq -r '.structure.workspaces[]? | [(.path // "-"), (.profile // "-"), ((.stage // "-")|tostring), (.rationale // "-"), (.verify_command // "-")] | map(if . == "" then "-" else . end) | join("\t")' "$MANIFEST" 2>/dev/null | tr -d '\r' ;;
    python) "$PY" -c '
import json, sys
try:
    d = json.load(open(sys.argv[1], encoding="utf-8"))
except Exception:
    sys.exit(0)
ws = ((d.get("structure") or {}).get("workspaces")) or []
for w in ws:
    print("\t".join([(str(w.get(k)) if w.get(k) not in (None, "") else "-").replace("\t", " ") for k in ("path", "profile", "stage", "rationale", "verify_command")]))' "$MANIFEST" 2>/dev/null | tr -d '\r' ;;
    *) return 1 ;;
  esac
}

# safe_path <ruta> → 0 si es relativa y no sale del proyecto
safe_path() {
  case "$1" in
    ""|-|/*|[A-Za-z]:*|..|../*|*/..|*/../*|*\\*) return 1 ;;
  esac
  return 0
}

# sha256 de stdin → hex
sha256_stdin() {
  if have sha256sum; then sha256sum | awk '{print $1}'
  elif have shasum; then shasum -a 256 | awk '{print $1}'
  elif have openssl; then openssl dgst -sha256 | awk '{print $NF}'
  elif [ -n "$PY" ]; then "$PY" -c 'import hashlib,sys; print(hashlib.sha256(sys.stdin.buffer.read()).hexdigest())'
  else return 1; fi
}
# manifest_tool <subcomando> [args] → scripts/manifest_tool.py con el Python 3 detectado
# (manifest_tool.py escribe finales de linea LF tambien en Windows: no hace falta tr)
manifest_tool() { PYTHONUTF8=1 "$PY" -I "$SCRIPT_DIR/manifest_tool.py" "$@"; }   # UTF-8 también en la consola de Windows
have_sha256() { have sha256sum || have shasum || have openssl || [ -n "$PY" ]; }

# block_ids_present <archivo> → 0 si algún marcador de inicio lleva id=
block_ids_present() { grep 'sfp:start' "$1" 2>/dev/null | grep -q 'id=[0-9]'; }

# block_content <archivo> <id> → líneas entre sfp:start id=<id> y su end (sin los marcadores).
# Si el archivo no usa ids (instalación anterior a 1.3.0), devuelve todos los bloques sin id.
block_content() {
  _mode=id
  block_ids_present "$1" || _mode=legacy
  awk -v id="$2" -v mode="$_mode" '
    /sfp:start/ {
      if (mode == "legacy") { if ($0 !~ /id=[0-9]/) { inb = 1; found = 1; next } }
      else if ($0 ~ ("id=" id "([^0-9]|$)")) { inb = 1; found = 1; next }
    }
    /sfp:end/ { if (inb) { inb = 0; next } }
    inb { print }
    END { exit found ? 0 : 1 }' "$1"
}

# remove_block <archivo> <id> → borra el bloque (marcadores incluidos), conservando permisos del archivo
remove_block() {
  _mode=id
  block_ids_present "$1" || _mode=legacy
  _tmp="${1}.sfp-tmp.$$"
  awk -v id="$2" -v mode="$_mode" '
    /sfp:start/ {
      if (mode == "legacy") { if ($0 !~ /id=[0-9]/) { inb = 1; next } }
      else if ($0 ~ ("id=" id "([^0-9]|$)")) { inb = 1; next }
    }
    /sfp:end/ { if (inb) { inb = 0; next } }
    !inb { print }' "$1" > "$_tmp" && cat "$_tmp" > "$1"
  _rc=$?
  rm -f "$_tmp"
  return $_rc
}

# fingerprint <tipo> <ruta> <markers> <id> → huella actual (vacío si no aplica: dirs, move, inexistente)
fingerprint() {
  case "$1" in
    merge) [ -f "$2" ] && block_content "$2" "$4" | sha256_stdin ;;
    configure)
      if [ "$3" = "true" ]; then [ -f "$2" ] && block_content "$2" "$4" | sha256_stdin
      else [ -f "$2" ] && sha256_stdin < "$2"; fi ;;
    create) [ -f "$2" ] && [ ! -L "$2" ] && sha256_stdin < "$2" ;;
    *) return 0 ;;
  esac
}

# ver_gt <a> <b> → 0 si la versión a es mayor que b (x.y.z numérico)
ver_gt() {
  [ "$1" = "$2" ] && return 1
  [ "$(printf '%s\n%s\n' "$1" "$2" | sort -t. -k1,1n -k2,2n -k3,3n | tail -1)" = "$1" ]
}
