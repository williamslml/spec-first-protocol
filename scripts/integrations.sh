#!/usr/bin/env bash
# integrations.sh — instala, configura, verifica y retira las candidatas del catálogo de skills/tools
# (references/architecture.md sección 6, sección 6.1 matriz de enrutamiento, sección 6.2 este script). Solo Claude Code.
#
# Componentes: archify · frontend-design · superpowers (solo 5 skills, nunca el plugin) · serena · rtk
# más el healthcheck de la propia skill sfp (spec-first-protocol). Requiere bash >= 4 (no sh/dash).
#
# Uso:
#   bash integrations.sh [modo] [opciones] [<ruta-del-proyecto>]       (por defecto: directorio actual)
#
# Modos (por defecto PLAN):
#   (ninguno)              PLAN de instalación: detecta y muestra lo que haría. No escribe nada.
#   --apply                Instala/configura, registra lo hecho en el estado y ejecuta el healthcheck.
#   --check                Solo healthcheck (no escribe nada).
#   --uninstall            PLAN de retiro de lo que ESTE script instaló (según el estado). No escribe.
#   --uninstall --apply    Retira lo del proyecto; lo global se imprime como [MANUAL] (decisión humana).
#
# Opciones de selección (se guardan en el estado con --apply; --check/--uninstall las reutilizan
# si no se pasan otra vez):
#   --scope project|global   Dónde instalar lo que NO exista globalmente (defecto: project).
#                            project = <proyecto>/.claude/skills y <proyecto>/.mcp.json (autocontenido).
#                            global  = ~/.claude/skills y MCP de usuario.
#   --rtk-scope global|project  Enganche de RTK (defecto: global, único modo con hook en Claude Code;
#                            project solo añade un bloque de instrucciones a <proyecto>/CLAUDE.md).
#   --only a,b,...           Solo estos componentes (archify,frontend-design,superpowers,serena,rtk).
#   --skip a,b,...           Excluir estos componentes.
#   --force-frontend         Instalar frontend-design aunque no se detecte frontend.
# Otras:
#   --state <archivo>        Estado (defecto: <proyecto>/.sfp/integrations.json; fuera del repo en el
#                            modo sin rastros).
#   -h, --help               Esta ayuda.
#
# Variables de entorno:
#   CLAUDE_CONFIG_DIR   Carpeta de configuración de Claude Code (defecto: ~/.claude), igual que Claude Code.
#   SFP_CLAUDE_JSON     Archivo de estado de Claude Code con los MCP de usuario (defecto: ~/.claude.json).
#
# Estados: [GLOBAL DETECTADO] [INSTALADO EN PROYECTO] [INSTALADO GLOBAL] [OMITIDO - YA CONFIGURADO]
#   [OMITIDO - NO SELECCIONADO] [OMITIDO - SIN FRONTEND] [PLAN] [OK] [AVISO] [CONFLICTO] [FALLA] [MANUAL]
#
# Códigos de salida: 0 = completo y sin fallas · 1 = fallas o conflictos · 2 = uso/ruta inválida ·
#                    3 = sin fallas pero INCOMPLETO (falta una dependencia para comprobar algo).
#
# Idempotente: cada acción se decide por detección del estado real; ejecutarlo N veces no duplica
# entradas de JSON/TOML ni reinstala lo que ya está. Nunca sobrescribe configuración existente:
# si encuentra una configuración distinta de la esperada, la reporta como [CONFLICTO] y no la toca.
# Solo registra (y por tanto solo retira) lo que instaló él mismo; lo preexistente no se toca.

set -euo pipefail

if [ -z "${BASH_VERSINFO:-}" ] || [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
  echo "ERROR: integrations.sh requiere bash >= 4 (macOS: 'brew install bash'). No usar sh/dash." >&2
  exit 2
fi

# --------------------------------------------------------------------------- versiones fijadas
# Verificadas el 2026-11-20 contra las fuentes oficiales. Para actualizar: cambiar aquí, revisar el
# repositorio en esa versión y repetir el healthcheck.
readonly SKILL_VERSION="1.14.0"
readonly SKILLS_CLI_PKG="skills@1.9.0"                                  # npm: CLI oficial de skills.sh
readonly ARCHIFY_SOURCE="tt-a1i/archify@v3.2.0"
readonly FRONTEND_SOURCE="anthropics/skills@e4bb5d960d87126ff3b3a8af1a104b7db67560ba"   # sin tags: commit
readonly SUPERPOWERS_SOURCE="obra/superpowers@v7.0.2"
readonly SERENA_PKG="serena-agent==2.1.0"
readonly SERENA_PY="3.13"
readonly RTK_VERSION="1.2.1"
readonly RTK_WINGET_ID="rtk-ai.rtk"
readonly RTK_INSTALL_SH="https://raw.githubusercontent.com/rtk-ai/rtk/refs/tags/v${RTK_VERSION}/install.sh"
readonly UV_VERSION="0.13.9"
readonly UV_WINGET_ID="astral-sh.uv"
readonly UV_INSTALL_SH="https://astral.sh/uv/${UV_VERSION}/install.sh"
readonly RTK_PROXY_BIND="127.0.0.1:8080"                                # llm_proxy::DEFAULT_BIND de RTK
readonly RTK_BLOCK_START="<!-- rtk-instructions"                        # bloque que escribe 'rtk init' local
readonly RTK_BLOCK_END="<!-- /rtk-instructions -->"

# Superpowers: solo lo que SFP no cubre (architecture.md sección 6.1). Lo demás está prohibido.
readonly SP_INCLUDE=(test-driven-development systematic-debugging verification-before-completion
                     receiving-code-review finishing-a-development-branch)
readonly SP_EXCLUDE=(brainstorming writing-plans executing-plans subagent-driven-development
                     dispatching-parallel-agents using-git-worktrees requesting-code-review
                     using-superpowers diagnosing-superpowers writing-skills)

# Serena: contexto claude-code (sin herramientas de lectura/búsqueda de texto) y sin memorias.
readonly SERENA_ARGS=(start-mcp-server --context claude-code --project-from-cwd --add-mode no-memories)
readonly SERENA_UVX=(uvx -p "$SERENA_PY" --from "$SERENA_PKG" serena "${SERENA_ARGS[@]}")

# RTK: comandos que nunca debe reescribir (scripts de SFP). Regex anclado ('^' = regex en RTK).
# La evidencia que ejecuta el agente (git, grep, find…) se protege con RTK_DISABLED=1 (sección 6.1).
readonly RTK_EXCLUDES=('^(ba)?sh .*spec-first-protocol' '^(powershell|pwsh).*spec-first-protocol'
                       '^python[0-9.]* .*manifest_tool\.py')

readonly ALL_COMPONENTS=(archify frontend-design superpowers serena rtk)

# --------------------------------------------------------------------------- argumentos
MODE=plan          # plan | apply | check | uninstall
APPLY=0
SCOPE=project
RTK_SCOPE=global
ONLY=""
SKIP=""
FORCE_FRONTEND=0
SEL_GIVEN=0
STATE_ARG=""
PROJECT_ARG=""

usage() { sed -n '2,48p' "$0" | sed 's/^# \{0,1\}//'; }
die_usage() { echo "ERROR: $1" >&2; echo "Ayuda: bash $0 --help" >&2; exit 2; }
set_mode() { [ "$MODE" = plan ] || [ "$MODE" = "$1" ] || die_usage "--check y --uninstall son excluyentes"; MODE="$1"; }

while [ $# -gt 0 ]; do
  case "$1" in
    --apply) APPLY=1 ;;
    --check) set_mode check ;;
    --uninstall) set_mode uninstall ;;
    --scope) [ $# -ge 2 ] || die_usage "--scope requiere valor"; SCOPE="$2"; SEL_GIVEN=1; shift ;;
    --scope=*) SCOPE="${1#*=}"; SEL_GIVEN=1 ;;
    --rtk-scope) [ $# -ge 2 ] || die_usage "--rtk-scope requiere valor"; RTK_SCOPE="$2"; SEL_GIVEN=1; shift ;;
    --rtk-scope=*) RTK_SCOPE="${1#*=}"; SEL_GIVEN=1 ;;
    --only) [ $# -ge 2 ] || die_usage "--only requiere valor"; ONLY="$2"; SEL_GIVEN=1; shift ;;
    --only=*) ONLY="${1#*=}"; SEL_GIVEN=1 ;;
    --skip) [ $# -ge 2 ] || die_usage "--skip requiere valor"; SKIP="$2"; SEL_GIVEN=1; shift ;;
    --skip=*) SKIP="${1#*=}"; SEL_GIVEN=1 ;;
    --force-frontend) FORCE_FRONTEND=1; SEL_GIVEN=1 ;;
    --state) [ $# -ge 2 ] || die_usage "--state requiere valor"; STATE_ARG="$2"; shift ;;
    --state=*) STATE_ARG="${1#*=}" ;;
    -h|--help) usage; exit 0 ;;
    -*) die_usage "opción desconocida: $1" ;;
    *) [ -z "$PROJECT_ARG" ] || die_usage "solo se admite una ruta de proyecto"; PROJECT_ARG="$1" ;;
  esac
  shift
done
[ "$MODE" = check ] && [ $APPLY = 1 ] && die_usage "--check no admite --apply"
[ "$MODE" = plan ] && [ $APPLY = 1 ] && MODE=apply

PROJ="${PROJECT_ARG:-.}"
[ -d "$PROJ" ] || die_usage "no existe el directorio del proyecto: $PROJ"
PROJ="$(cd "$PROJ" && pwd)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SFP_DIR="$(dirname "$SCRIPT_DIR")"
CLAUDE_HOME="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
CLAUDE_JSON="${SFP_CLAUDE_JSON:-$HOME/.claude.json}"
STATE="${STATE_ARG:-$PROJ/.sfp/integrations.json}"

# --------------------------------------------------------------------------- utilidades
have() { command -v "$1" >/dev/null 2>&1; }

case "$(uname -s 2>/dev/null || echo unknown)" in
  MINGW*|MSYS*|CYGWIN*) OS=windows ;;
  Darwin) OS=macos ;;
  *) OS=linux ;;
esac

# Ruta en formato del sistema para programas nativos (Python/Node en Windows no entienden /c/...).
native() { if have cygpath; then cygpath -m "$1"; else printf '%s\n' "$1"; fi; }

PY=""
for _c in python3 python; do
  if have "$_c" && "$_c" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 8) else 1)' >/dev/null 2>&1; then
    PY="$_c"; break
  fi
done

FAILS=0
INCOMPLETE=0
declare -a SUMMARY=()

status() { # status <ETIQUETA> <componente> <mensaje>
  printf '  %-30s %-16s %s\n' "[$1]" "$2" "$3"
  case "$1" in
    FALLA|CONFLICTO) FAILS=$((FAILS + 1)) ;;
  esac
}
incomplete() { status AVISO "$1" "NO comprobado: $2"; INCOMPLETE=$((INCOMPLETE + 1)); }
section() { printf '\n== %s\n' "$1"; }
record() { SUMMARY+=("$(printf '%-16s %s' "$1" "$2")"); }

# helper <subcomando> [args...]: lógica JSON/TOML/estado en integrations_helpers.py (biblioteca estándar).
helper() { PYTHONUTF8=1 "$PY" -I "$(native "$SCRIPT_DIR/integrations_helpers.py")" "$@"; }

# Selección: si no se pasó ninguna opción de selección, se reutiliza la guardada en el estado.
if [ $SEL_GIVEN = 0 ] && [ "$MODE" != apply ] && [ -n "$PY" ] && [ -f "$STATE" ]; then
  while IFS='=' read -r _k _v; do
    _v="${_v%$'\r'}"
    case "$_k" in
      only) ONLY="$_v" ;; skip) SKIP="$_v" ;; scope) SCOPE="$_v" ;; rtk_scope) RTK_SCOPE="$_v" ;;
      force_frontend) FORCE_FRONTEND="$_v" ;;
    esac
  done < <(helper state-select "$(native "$STATE")")
  SEL_FROM_STATE=1
else
  SEL_FROM_STATE=0
fi

case "$SCOPE" in project|global) ;; *) die_usage "--scope debe ser project o global" ;; esac
case "$RTK_SCOPE" in project|global) ;; *) die_usage "--rtk-scope debe ser project o global" ;; esac
for list in "$ONLY" "$SKIP"; do
  IFS=',' read -r -a _items <<< "$list"
  for c in "${_items[@]:-}"; do
    [ -z "$c" ] && continue
    case " ${ALL_COMPONENTS[*]} " in *" $c "*) ;; *) die_usage "componente desconocido: $c" ;; esac
  done
done

selected() { # selected <componente> → 0 si está seleccionado
  local c="$1"
  if [ -n "$ONLY" ]; then case ",$ONLY," in *",$c,"*) ;; *) return 1 ;; esac; fi
  if [ -n "$SKIP" ]; then case ",$SKIP," in *",$c,"*) return 1 ;; esac; fi
  return 0
}

# run <componente> <descripción> -- <comando...>: en PLAN solo muestra; con --apply ejecuta.
run() {
  local comp="$1" desc="$2"; shift 3
  if [ $APPLY = 1 ]; then
    status EJECUTANDO "$comp" "$desc"
    printf '      $ %s\n' "$*"
    if "$@"; then return 0; fi
    status FALLA "$comp" "falló: $desc"
    return 1
  fi
  status PLAN "$comp" "$desc"
  printf '      $ %s\n' "$*"
  return 0
}

# remember <comp> <ámbito> <tipo> <auto:0|1> <objetivo> <deshacer>: registra lo instalado (solo con --apply).
remember() {
  [ $APPLY = 1 ] || return 0
  [ -n "$PY" ] || { status AVISO "$1" "sin Python 3 no se registra en $STATE: el retiro de esto será manual"; return 0; }
  helper state-add "$(native "$STATE")" "$@"
}

# Añade al FINAL del PATH de esta ejecución las carpetas donde los instaladores oficiales dejan
# los ejecutables (para encontrarlos sin abrir otra terminal). Al final, para no alterar la
# precedencia del PATH del usuario.
add_path_if() { [ -d "$1" ] && case ":$PATH:" in *":$1:"*) ;; *) PATH="$PATH:$1" ;; esac; return 0; }
refresh_path() {
  add_path_if "$HOME/.local/bin"
  add_path_if "$HOME/.cargo/bin"
  if [ "$OS" = windows ] && [ -n "${LOCALAPPDATA:-}" ]; then
    local _la _p _d
    _la="$(cygpath -u "$LOCALAPPDATA" 2>/dev/null || echo "$LOCALAPPDATA")"
    add_path_if "$_la/Microsoft/WinGet/Links"
    add_path_if "$_la/Microsoft/WindowsApps"     # winget.exe vive aquí y Git Bash no siempre lo incluye
    # winget y otros instaladores amplían el PATH de usuario en el registro, que un shell ya abierto no
    # ve: se releen los PATH de usuario y de máquina y se añaden al final las carpetas que falten.
    if have powershell.exe; then
      _p=$(powershell.exe -NoProfile -NonInteractive -Command "[Environment]::GetEnvironmentVariable('Path','User') + ';' + [Environment]::GetEnvironmentVariable('Path','Machine')" 2>/dev/null | tr -d '\r') || _p=""
      local IFS=';'
      for _d in $_p; do
        [ -n "$_d" ] && add_path_if "$(cygpath -u "$_d" 2>/dev/null || printf '%s' "$_d")"
      done
    fi
  fi
  hash -r
}
refresh_path
winget_cmd() { command -v winget 2>/dev/null || command -v winget.exe 2>/dev/null; }

# skill_dir <scope:global|project> <nombre> → ruta de la carpeta de la skill
skill_dir() { if [ "$1" = global ]; then echo "$CLAUDE_HOME/skills/$2"; else echo "$PROJ/.claude/skills/$2"; fi; }
skill_at() { [ -f "$(skill_dir "$1" "$2")/SKILL.md" ]; }

# skill_name_ok <dir> <nombre>: el frontmatter declara ese nombre
skill_name_ok() { grep -Eq "^name:[[:space:]]*\"?$2\"?[[:space:]]*$" "$1/SKILL.md" 2>/dev/null; }

# plugin_enabled <nombre>: el plugin está habilitado en settings de usuario o del proyecto,
# o figura en installed_plugins.json. Imprime dónde.
plugin_enabled() {
  [ -n "$PY" ] || return 2
  helper plugin-enabled "$1" "$(native "$CLAUDE_HOME/settings.json")" "$(native "$PROJ/.claude/settings.json")" \
    "$(native "$PROJ/.claude/settings.local.json")" "$(native "$CLAUDE_HOME/plugins/installed_plugins.json")"
}

# skills CLI (npx), versión fijada. skills_add <scope> <origen> <skill...> · skills_remove <scope> <skill...>
skills_cli() { ( cd "$PROJ" && DISABLE_TELEMETRY=1 DO_NOT_TRACK=1 npx -y "$SKILLS_CLI_PKG" "$@" ); }
skills_add() {
  local scope="$1" src="$2"; shift 2
  local args=(add "$src" --skill "$@" --agent claude-code --copy --yes)
  [ "$scope" = global ] && args+=(--global)
  skills_cli "${args[@]}"
}
skills_undo_cmd() { # texto del comando que deshace la instalación (para el estado)
  local scope="$1"; shift
  printf 'npx -y %s remove%s --agent claude-code -y %s' "$SKILLS_CLI_PKG" "$([ "$scope" = global ] && echo ' --global')" "$*"
}

node_ok() { have node && have npx && node -e 'process.exit(+process.versions.node.split(".")[0] >= 18 ? 0 : 1)' >/dev/null 2>&1; }

# --------------------------------------------------------------------------- frontend
has_frontend() {
  if [ -f "$PROJ/package.json" ] &&
     grep -Eq '"(react|react-dom|vue|svelte|@angular/core|next|nuxt|solid-js|preact|astro|lit|@remix-run/react|@sveltejs/kit)"[[:space:]]*:' "$PROJ/package.json"; then
    return 0
  fi
  # Se podan las carpetas generadas (incluidos los diagramas de archify y los informes de cobertura),
  # que contienen HTML/CSS sin ser frontend del proyecto.
  local hit
  hit=$(find "$PROJ" -maxdepth 5 \( -name .git -o -name node_modules -o -name vendor -o -name dist -o -name build \
          -o -name .venv -o -name .claude -o -name .sfp -o -name .archify -o -name htmlcov -o -name coverage \
          -o -name site -o -name _build -o -name target \) -prune -o \
        -type f \( -name '*.tsx' -o -name '*.jsx' -o -name '*.vue' -o -name '*.svelte' -o -name '*.html' -o -name '*.css' -o -name '*.scss' \) -print 2>/dev/null | head -n 1) || hit=""
  [ -n "$hit" ]
}

# --------------------------------------------------------------------------- componente: skill simple
# ensure_skill <componente> <origen> <nombre-skill>
ensure_skill() {
  local comp="$1" src="$2" name="$3" g=0 p=0
  skill_at global "$name" && g=1
  skill_at project "$name" && p=1
  if [ $g = 1 ] && [ $p = 1 ]; then
    status AVISO "$comp" "existe en global y en proyecto ($name): dos copias; conservar una (decisión humana)"
  fi
  if [ $g = 1 ]; then
    status "GLOBAL DETECTADO" "$comp" "$(skill_dir global "$name") — el proyecto la usa sin duplicarla"
    record "$comp" "GLOBAL DETECTADO"; return 0
  fi
  if [ $p = 1 ]; then
    status "OMITIDO - YA CONFIGURADO" "$comp" "$(skill_dir project "$name")"
    record "$comp" "OMITIDO - YA CONFIGURADO"; return 0
  fi
  if ! node_ok; then
    status FALLA "$comp" "requiere Node.js >= 18 y npx (no encontrados)"; record "$comp" "FALLA"; return 0
  fi
  if ! run "$comp" "instalar $name ($src) en ámbito $SCOPE" -- skills_add "$SCOPE" "$src" "$name"; then
    record "$comp" "FALLA"; return 0
  fi
  [ $APPLY = 1 ] || { record "$comp" "PLAN"; return 0; }
  if ! skill_at "$SCOPE" "$name"; then
    status FALLA "$comp" "el instalador terminó pero no existe $(skill_dir "$SCOPE" "$name")/SKILL.md"; record "$comp" "FALLA"; return 0
  fi
  if [ "$SCOPE" = project ]; then
    status "INSTALADO EN PROYECTO" "$comp" "$(skill_dir project "$name")"; record "$comp" "INSTALADO EN PROYECTO"
    remember "$comp" project skill 1 "$name" "$(skills_undo_cmd project "$name")"
  else
    status "INSTALADO GLOBAL" "$comp" "$(skill_dir global "$name") (global: retiro [MANUAL])"; record "$comp" "INSTALADO GLOBAL"
    remember "$comp" global skill 0 "$name" "$(skills_undo_cmd global "$name")"
  fi
}

do_archify() { ensure_skill archify "$ARCHIFY_SOURCE" archify; }

do_frontend() {
  if [ "$FORCE_FRONTEND" = 0 ] && ! has_frontend && ! skill_at project frontend-design && ! skill_at global frontend-design; then
    status "OMITIDO - SIN FRONTEND" frontend-design "no se detectó frontend (usar --force-frontend para instalarlo igual)"
    record frontend-design "OMITIDO - SIN FRONTEND"; return 0
  fi
  local where=""
  if [ -n "$PY" ] && where=$(plugin_enabled frontend-design); then
    status "GLOBAL DETECTADO" frontend-design "como plugin: ${where//$'\n'/; }"
    record frontend-design "GLOBAL DETECTADO (plugin)"; return 0
  fi
  ensure_skill frontend-design "$FRONTEND_SOURCE" frontend-design
}

do_superpowers() {
  local comp=superpowers where="" n s missing=() conflict=0
  if [ -z "$PY" ]; then
    incomplete $comp "no hay Python 3 para comprobar si el plugin está habilitado"
  elif where=$(plugin_enabled superpowers); then
    status CONFLICTO $comp "plugin completo habilitado (${where//$'\n'/; }): trae el hook SessionStart y skills que solapan SFP"
    status MANUAL $comp "decisión humana: claude plugin uninstall superpowers  (luego repetir este script)"
    record $comp "CONFLICTO (plugin)"; return 0
  fi
  for n in "${SP_EXCLUDE[@]}"; do
    for s in global project; do
      if skill_at "$s" "$n"; then
        status CONFLICTO $comp "skill excluida por sección 6.1 presente: $(skill_dir "$s" "$n") (solapa SFP; retirarla es decisión humana)"
        conflict=1
      fi
    done
  done
  for n in "${SP_INCLUDE[@]}"; do
    if skill_at global "$n"; then status "GLOBAL DETECTADO" $comp "$n ($(skill_dir global "$n"))"
    elif skill_at project "$n"; then status "OMITIDO - YA CONFIGURADO" $comp "$n ($(skill_dir project "$n"))"
    else missing+=("$n"); fi
  done
  if [ ${#missing[@]} -eq 0 ]; then
    record $comp "$([ $conflict = 1 ] && echo CONFLICTO || echo 'OMITIDO - YA CONFIGURADO')"; return 0
  fi
  if ! node_ok; then status FALLA $comp "requiere Node.js >= 18 y npx"; record $comp FALLA; return 0; fi
  if ! run $comp "instalar ${#missing[@]} skills (${missing[*]}) en ámbito $SCOPE; sin plugin ni hooks" -- \
       skills_add "$SCOPE" "$SUPERPOWERS_SOURCE" "${missing[@]}"; then
    record $comp FALLA; return 0
  fi
  [ $APPLY = 1 ] || { record $comp PLAN; return 0; }
  local bad=0
  for n in "${missing[@]}"; do skill_at "$SCOPE" "$n" || { status FALLA $comp "no quedó instalada: $n"; bad=1; }; done
  # El instalador no debe haber traído skills excluidas.
  for n in "${SP_EXCLUDE[@]}"; do if skill_at "$SCOPE" "$n"; then status CONFLICTO $comp "el instalador trajo una skill excluida: $n"; bad=1; fi; done
  [ $bad = 0 ] || { record $comp FALLA; return 0; }
  if [ "$SCOPE" = project ]; then
    status "INSTALADO EN PROYECTO" $comp "${missing[*]}"; record $comp "INSTALADO EN PROYECTO"
    for n in "${missing[@]}"; do remember $comp project skill 1 "$n" "$(skills_undo_cmd project "$n")"; done
  else
    status "INSTALADO GLOBAL" $comp "${missing[*]} (global: retiro [MANUAL])"; record $comp "INSTALADO GLOBAL"
    for n in "${missing[@]}"; do remember $comp global skill 0 "$n" "$(skills_undo_cmd global "$n")"; done
  fi
}

# --------------------------------------------------------------------------- serena
# serena_entry → imprime "<ámbito>\t<command> <args...>" de la entrada MCP 'serena' existente
serena_entry() {
  [ -n "$PY" ] || return 2
  helper mcp-entry "$(native "$PROJ/.mcp.json")" "$(native "$CLAUDE_JSON")" "$(native "$PROJ")" serena
}
# serena_conforms <línea de comando> → 0 si respeta sección 6.1 (contexto claude-code y sin memorias)
serena_conforms() { case "$1" in *"--context claude-code"*) ;; *) return 1 ;; esac; case "$1" in *no-memories*) return 0 ;; *) return 1 ;; esac; }

# Añade la entrada 'serena' a <proyecto>/.mcp.json sin tocar las demás ni reformatear (idempotente).
write_project_mcp() { helper mcp-add "$(native "$PROJ/.mcp.json")" serena "$@"; }

install_uv() {
  if [ "$OS" = windows ]; then
    winget_cmd >/dev/null || { status FALLA serena "uv no está y no hay winget: instalar uv a mano (https://docs.astral.sh/uv/)"; return 1; }
    "$(winget_cmd)" install --id "$UV_WINGET_ID" -e --version "$UV_VERSION" --accept-source-agreements --accept-package-agreements
  else
    have curl || { status FALLA serena "uv no está y no hay curl"; return 1; }
    curl -LsSf "$UV_INSTALL_SH" | sh
  fi
  refresh_path
}
uv_undo_cmd() {
  if [ "$OS" = windows ]; then echo "winget uninstall --id $UV_WINGET_ID -e"
  else echo "rm ~/.local/bin/uv ~/.local/bin/uvx  (ver https://docs.astral.sh/uv/getting-started/installation/#uninstallation)"; fi
}

do_serena() {
  local comp=serena entry
  if [ -z "$PY" ]; then incomplete $comp "requiere Python 3 para leer/escribir la configuración MCP"; record $comp INCOMPLETO; return 0; fi
  if entry=$(serena_entry); then
    local scope="${entry%%$'\t'*}" cmd="${entry#*$'\t'}"
    if serena_conforms "$cmd"; then
      status "OMITIDO - YA CONFIGURADO" $comp "MCP 'serena' ($scope): $cmd"; record $comp "OMITIDO - YA CONFIGURADO"
    else
      status CONFLICTO $comp "MCP 'serena' ($scope) sin --context claude-code y/o --add-mode no-memories (sección 6.1): $cmd"
      status MANUAL $comp "decisión humana: ajustar esa entrada; el script no sobrescribe configuración existente"
      record $comp CONFLICTO
    fi
    return 0
  fi
  local have_uv=0
  have uv && have uvx && have_uv=1
  if [ "$SCOPE" = project ]; then
    # Autocontenido y portable: siempre vía uvx con versión fijada (no depende de un binario global).
    if [ $have_uv = 0 ]; then
      run $comp "instalar uv $UV_VERSION (requisito de Serena; global por necesidad)" -- install_uv || { record $comp FALLA; return 0; }
      if [ $APPLY = 1 ]; then
        have uvx || { status FALLA $comp "uv instalado pero uvx no está en PATH: abrir una terminal nueva y repetir"; record $comp FALLA; return 0; }
        status "INSTALADO GLOBAL" $comp "uv $UV_VERSION (global: retiro [MANUAL])"
        remember $comp global binary 0 uv "$(uv_undo_cmd)"
      fi
    else
      status "GLOBAL DETECTADO" $comp "uv $(uv --version 2>/dev/null | head -n1 | tr -d '\r')"
    fi
    run $comp "registrar Serena en $PROJ/.mcp.json vía uvx ($SERENA_PKG, Python $SERENA_PY)" -- \
      write_project_mcp "${SERENA_UVX[@]}" || { record $comp FALLA; return 0; }
    if [ $APPLY = 1 ]; then
      status "INSTALADO EN PROYECTO" $comp "$PROJ/.mcp.json (Claude Code pedirá aprobar el servidor la primera vez)"
      record $comp "INSTALADO EN PROYECTO"
      remember $comp project mcp 1 ".mcp.json#serena" "${SERENA_UVX[*]}"
    else record $comp PLAN; fi
    return 0
  fi
  # Ámbito global: binario con uv tool + MCP de usuario.
  have claude || [ $APPLY = 0 ] || { status FALLA $comp "falta el CLI 'claude' para registrar el MCP de usuario"; record $comp FALLA; return 0; }
  if have serena; then
    status "GLOBAL DETECTADO" $comp "binario $(command -v serena)"
  else
    if [ $have_uv = 0 ]; then
      run $comp "instalar uv $UV_VERSION (global)" -- install_uv || { record $comp FALLA; return 0; }
      [ $APPLY = 1 ] && remember $comp global binary 0 uv "$(uv_undo_cmd)"
    fi
    run $comp "instalar $SERENA_PKG con uv tool (global)" -- uv tool install -p "$SERENA_PY" "$SERENA_PKG" || { record $comp FALLA; return 0; }
    [ $APPLY = 1 ] && remember $comp global binary 0 serena-agent "uv tool uninstall serena-agent"
    refresh_path
    if [ ! -f "$HOME/.serena/serena_config.yml" ]; then
      run $comp "inicializar Serena (crea ~/.serena/serena_config.yml)" -- serena init || { record $comp FALLA; return 0; }
    fi
  fi
  run $comp "registrar MCP 'serena' de usuario" -- claude mcp add --scope user serena -- serena "${SERENA_ARGS[@]}" || { record $comp FALLA; return 0; }
  if [ $APPLY = 1 ]; then
    status "INSTALADO GLOBAL" $comp "MCP de usuario (global: retiro [MANUAL])"; record $comp "INSTALADO GLOBAL"
    remember $comp global mcp 0 "user#serena" "claude mcp remove --scope user serena"
  else record $comp PLAN; fi
}

# --------------------------------------------------------------------------- rtk
rtk_ok() { have rtk && rtk --version >/dev/null 2>&1 && rtk gain >/dev/null 2>&1; }

install_rtk() {
  case "$OS" in
    windows)
      winget_cmd >/dev/null || { status FALLA rtk "no hay winget: ver https://www.rtk-ai.app/docs/getting-started/installation/"; return 1; }
      "$(winget_cmd)" install --id "$RTK_WINGET_ID" -e --version "$RTK_VERSION" --accept-source-agreements --accept-package-agreements ;;
    *)
      have curl || { status FALLA rtk "no hay curl para el instalador oficial"; return 1; }
      curl -fsSL "$RTK_INSTALL_SH" | RTK_VERSION="v$RTK_VERSION" sh ;;
  esac
  refresh_path
}
rtk_undo_cmd() {
  if [ "$OS" = windows ]; then echo "winget uninstall --id $RTK_WINGET_ID -e"; else echo "rm ~/.local/bin/rtk"; fi
}

# rtk_hook_global → 0 si ~/.claude/settings.json tiene un hook PreToolUse que llama a rtk
rtk_hook_global() { helper hook-has "$(native "$CLAUDE_HOME/settings.json")" PreToolUse rtk; }
rtk_block_project() { helper block-has "$(native "$PROJ/CLAUDE.md")" "$RTK_BLOCK_START"; }

# rtk_proxy_env <settings.json> → 0 si ANTHROPIC_BASE_URL apunta al proxy de RTK (prohibido por sección 6.1)
rtk_proxy_env() { helper env-has "$(native "$1")" ANTHROPIC_BASE_URL "$RTK_PROXY_BIND"; }

rtk_config_path() { { rtk config 2>/dev/null || true; } | sed -n 's/^Config: //p' | head -n 1 | tr -d '\r'; }

# rtk_excludes <archivo> <check|apply|remove>
rtk_excludes() { helper toml-list "$2" "$(native "$1")" hooks exclude_commands "${RTK_EXCLUDES[@]}"; }

do_rtk() {
  local comp=rtk cfg changed=0 installed=0
  if [ -z "$PY" ]; then incomplete $comp "requiere Python 3 para leer settings.json y config.toml"; record $comp INCOMPLETO; return 0; fi
  if rtk_ok; then
    status "GLOBAL DETECTADO" $comp "binario $(command -v rtk) ($(rtk --version 2>/dev/null | head -n1 | tr -d '\r'))"
    installed=1
  elif have rtk; then
    status CONFLICTO $comp "'rtk' en PATH ($(command -v rtk), $(rtk --version 2>/dev/null | head -n1 | tr -d '\r')) no es rtk-ai/rtk: 'rtk gain' falla (homónimo de crates.io)"
    status MANUAL $comp "decisión humana: retirarlo (si vino de cargo: cargo uninstall rtk) y repetir este script, que instalará rtk-ai/rtk"
    record $comp CONFLICTO; return 0
  else
    run $comp "instalar el binario rtk $RTK_VERSION (global por necesidad: es un ejecutable)" -- install_rtk || { record $comp FALLA; return 0; }
    if [ $APPLY = 1 ]; then
      rtk_ok || { status FALLA $comp "rtk instalado pero no accesible: abrir una terminal nueva y repetir"; record $comp FALLA; return 0; }
      status "INSTALADO GLOBAL" $comp "rtk $RTK_VERSION (global: retiro [MANUAL])"
      remember $comp global binary 0 rtk "$(rtk_undo_cmd)"
      installed=1; changed=1
    fi
  fi

  # Enganche al runtime
  if [ "$RTK_SCOPE" = global ]; then
    if rtk_hook_global; then
      status "OMITIDO - YA CONFIGURADO" $comp "hook PreToolUse en $CLAUDE_HOME/settings.json"
    else
      # --auto-patch nunca adopta el proxy de API (verificado en el código de rtk init: solo el modo
      # interactivo lo ofrece); stdin vacío → cualquier pregunta queda en "N" (telemetría desactivada).
      run $comp "registrar el hook global (rtk init -g --auto-patch; sin proxy, sin telemetría)" -- \
        sh -c 'rtk init -g --auto-patch </dev/null' || { record $comp FALLA; return 0; }
      if [ $APPLY = 1 ]; then
        status "INSTALADO GLOBAL" $comp "hook en $CLAUDE_HOME/settings.json y ~/.claude/RTK.md (global: retiro [MANUAL])"
        remember $comp global hook 0 "settings.json#PreToolUse:rtk" "rtk init -g --uninstall"
        changed=1
      fi
    fi
  else
    if rtk_block_project; then
      status "OMITIDO - YA CONFIGURADO" $comp "bloque $RTK_BLOCK_START en $PROJ/CLAUDE.md"
    else
      # 'rtk init' local (verificado en su código): sin hook, solo el bloque en CLAUDE.md y .rtk/filters.toml.
      run $comp "añadir el bloque de instrucciones RTK al proyecto (rtk init --auto-patch; sin hook)" -- \
        sh -c 'cd "$1" && rtk init --auto-patch </dev/null' _ "$PROJ" || { record $comp FALLA; return 0; }
      if [ $APPLY = 1 ]; then
        status "INSTALADO EN PROYECTO" $comp "$PROJ/CLAUDE.md (+ .rtk/filters.toml)"
        remember $comp project block 1 "CLAUDE.md#rtk-instructions" "quitar el bloque $RTK_BLOCK_START … $RTK_BLOCK_END"
        remember $comp project file 0 ".rtk/filters.toml" "borrar .rtk/filters.toml si no se personalizó"
        changed=1
      fi
    fi
  fi

  # Exclusiones de los scripts de SFP en config.toml de RTK (archivo GLOBAL del usuario)
  if [ $installed = 0 ]; then
    status PLAN $comp "(global) añadir a [hooks].exclude_commands de config.toml: ${RTK_EXCLUDES[*]}"
  else
    cfg=$(rtk_config_path) || cfg=""
    if [ -z "$cfg" ]; then status FALLA $comp "no se pudo leer la ruta de config.toml ('rtk config')"; record $comp FALLA; return 0; fi
    cfg=$(cygpath -u "$cfg" 2>/dev/null || echo "$cfg")
    local rc=0
    [ -f "$cfg" ] && { rtk_excludes "$cfg" check >/dev/null || rc=$?; } || rc=1
    if [ $rc = 0 ]; then
      status "OMITIDO - YA CONFIGURADO" $comp "(global) exclusiones de SFP en $cfg"
    elif [ $rc = 3 ]; then
      incomplete $comp "Python >= 3.11 necesario para editar config.toml"
    else
      # 'rtk config --create' SOBRESCRIBE con valores por defecto: solo se usa si el archivo no existe.
      if [ ! -f "$cfg" ]; then run $comp "(global) crear $cfg con valores por defecto" -- sh -c 'rtk config --create >/dev/null' || { record $comp FALLA; return 0; }; fi
      run $comp "(global) fusionar exclusiones de SFP en $cfg (sin tocar el resto)" -- rtk_excludes "$cfg" apply || { record $comp FALLA; return 0; }
      if [ $APPLY = 1 ]; then
        remember $comp global toml 0 "$(native "$cfg")#hooks.exclude_commands" \
          "PYTHONUTF8=1 $PY $(native "$SCRIPT_DIR/integrations_helpers.py") toml-list remove $(native "$cfg") hooks exclude_commands ${RTK_EXCLUDES[*]}"
        changed=1
      fi
    fi
  fi
  if rtk_proxy_env "$CLAUDE_HOME/settings.json"; then
    status CONFLICTO $comp "ANTHROPIC_BASE_URL apunta al proxy de RTK ($RTK_PROXY_BIND): prohibido por sección 6.1; retirarlo es decisión humana"
  fi
  if [ $APPLY = 0 ]; then record $comp PLAN
  elif [ $changed = 1 ]; then record $comp CONFIGURADO
  else record $comp "OMITIDO - YA CONFIGURADO"; fi
}

# --------------------------------------------------------------------------- healthcheck
hc_skill() { # hc_skill <componente> <nombre> → imprime la carpeta encontrada
  local s
  for s in project global; do
    if skill_at "$s" "$2"; then
      if skill_name_ok "$(skill_dir "$s" "$2")" "$2"; then skill_dir "$s" "$2"; return 0; fi
      status FALLA "$1" "$(skill_dir "$s" "$2")/SKILL.md no declara name: $2"; return 1
    fi
  done
  return 1
}

healthcheck() {
  section "HEALTHCHECK"
  [ $SEL_FROM_STATE = 1 ] && echo "  (selección leída de $STATE: only='$ONLY' skip='$SKIP' scope=$SCOPE rtk-scope=$RTK_SCOPE force-frontend=$FORCE_FRONTEND)"
  local d n s entry cfg

  # 1. sfp
  if [ -f "$SFP_DIR/SKILL.md" ] && skill_name_ok "$SFP_DIR" spec-first-protocol; then
    local bad=0 f
    for f in "$SFP_DIR"/scripts/*.sh; do bash -n "$f" 2>/dev/null || { status FALLA sfp "error de sintaxis: $f"; bad=1; }; done
    grep -q '^### 6.1 Matriz de responsabilidades' "$SFP_DIR/references/architecture.md" || { status FALLA sfp "falta la matriz sección 6.1 en references/architecture.md"; bad=1; }
    [ $bad = 0 ] && status OK sfp "$SFP_DIR (scripts con sintaxis válida, matriz sección 6.1 presente)"
  else
    status FALLA sfp "no se encuentra la skill spec-first-protocol en $SFP_DIR"
  fi

  # 2. archify
  if selected archify; then
    if d=$(hc_skill archify archify); then
      if ! have node; then incomplete archify "falta Node.js para 'archify doctor'"
      elif ARCHIFY_UPDATE_CHECK_DISABLED=1 node "$(native "$d/bin/archify.mjs")" doctor >/dev/null 2>&1; then status OK archify "$d (archify doctor sin errores)"
      else status FALLA archify "'archify doctor' falló en $d"; fi
    else status FALLA archify "no instalada (ni en proyecto ni global)"; fi
  fi

  # 3. frontend-design (instalada → se verifica; no instalada y sin frontend → correcto)
  if selected frontend-design; then
    if [ -n "$PY" ] && entry=$(plugin_enabled frontend-design); then status OK frontend-design "plugin: ${entry//$'\n'/; }"
    elif d=$(hc_skill frontend-design frontend-design); then status OK frontend-design "$d"
    elif [ "$FORCE_FRONTEND" = 0 ] && ! has_frontend; then status OK frontend-design "no instalada: el proyecto no tiene frontend (correcto según sección 6)"
    else status FALLA frontend-design "no instalada"; fi
  fi

  # 4. superpowers (subconjunto)
  if selected superpowers; then
    local ok=1
    if [ -z "$PY" ]; then incomplete superpowers "sin Python 3 no se comprueba el plugin"
    elif entry=$(plugin_enabled superpowers); then status CONFLICTO superpowers "plugin completo habilitado: ${entry//$'\n'/; }"; ok=0; fi
    for n in "${SP_INCLUDE[@]}"; do hc_skill superpowers "$n" >/dev/null || { status FALLA superpowers "falta la skill $n"; ok=0; }; done
    for n in "${SP_EXCLUDE[@]}"; do
      for s in project global; do if skill_at "$s" "$n"; then status CONFLICTO superpowers "skill excluida presente: $(skill_dir "$s" "$n")"; ok=0; fi; done
    done
    [ $ok = 1 ] && status OK superpowers "5 skills complementarias presentes; ninguna excluida; sin plugin"
  fi

  # 5. serena
  if selected serena; then
    if [ -z "$PY" ]; then incomplete serena "sin Python 3 no se lee la configuración MCP"
    elif entry=$(serena_entry); then
      local cmdline="${entry#*$'\t'}" first
      first="${cmdline%% *}"
      if ! serena_conforms "$cmdline"; then status CONFLICTO serena "la entrada MCP no usa --context claude-code y --add-mode no-memories (sección 6.1): $cmdline"
      elif ! have "$first"; then status FALLA serena "el comando '$first' de la entrada MCP no está en PATH"
      else status OK serena "MCP ${entry%%$'\t'*}: $cmdline"; fi
    else status FALLA serena "no hay entrada MCP 'serena' (proyecto, local ni usuario)"; fi
  fi

  # 6. rtk
  if selected rtk; then
    if ! rtk_ok; then status FALLA rtk "binario rtk-ai/rtk no accesible"
    elif [ -z "$PY" ]; then incomplete rtk "sin Python 3 no se comprueban hook ni exclusiones"
    else
      local ok=1 rc=0
      if [ "$RTK_SCOPE" = global ]; then rtk_hook_global || { status FALLA rtk "falta el hook PreToolUse en $CLAUDE_HOME/settings.json"; ok=0; }
      else rtk_block_project || { status FALLA rtk "falta el bloque $RTK_BLOCK_START en $PROJ/CLAUDE.md"; ok=0; }; fi
      cfg=$(rtk_config_path) || cfg=""
      cfg=$(cygpath -u "$cfg" 2>/dev/null || echo "$cfg")
      if [ -n "$cfg" ] && [ -f "$cfg" ]; then
        rtk_excludes "$cfg" check >/dev/null || rc=$?
        case $rc in 0) ;; 3) incomplete rtk "Python >= 3.11 necesario para leer config.toml" ;; *) status FALLA rtk "faltan exclusiones de SFP en $cfg"; ok=0 ;; esac
      else status FALLA rtk "no existe config.toml de RTK (exclusiones de SFP sin aplicar)"; ok=0; fi
      if rtk_proxy_env "$CLAUDE_HOME/settings.json"; then status CONFLICTO rtk "proxy de API de RTK activo en settings.json"; ok=0; fi
      [ $ok = 1 ] && [ $rc = 0 ] && status OK rtk "binario, enganche ($RTK_SCOPE) y exclusiones de SFP correctos"
    fi
  fi

  # 7. colisiones de nombres de skill entre ámbitos (la misma skill dos veces)
  for n in archify frontend-design "${SP_INCLUDE[@]}"; do
    if skill_at global "$n" && skill_at project "$n"; then status AVISO colisiones "$n existe en global y en proyecto: dos copias que pueden divergir"; fi
  done
  return 0
}

# --------------------------------------------------------------------------- retiro
uninstall_all() {
  section "RETIRO (solo lo que registró este script en $STATE)"
  if [ -z "$PY" ]; then incomplete retiro "sin Python 3 no se lee el estado"; return 0; fi
  if [ ! -f "$STATE" ]; then
    echo "  No hay estado: este script no instaló nada en este proyecto (o se usó otro --state)."
    return 0
  fi
  local lines=() line idx comp scope kind auto target undo done_idx=()
  mapfile -t lines < <(helper state-list "$(native "$STATE")")
  # Orden inverso al de instalación.
  local i
  for (( i=${#lines[@]}-1; i>=0; i-- )); do
    line="${lines[$i]%$'\r'}"
    IFS=$'\t' read -r idx comp scope kind auto target undo <<< "$line"
    if [ "$auto" != 1 ]; then
      status MANUAL "$comp" "($scope $kind $target) decisión humana: $undo"
      continue
    fi
    case "$kind" in
      skill)
        if run "$comp" "retirar la skill $target del proyecto" -- skills_cli remove "$target" --agent claude-code -y; then
          if [ $APPLY = 1 ]; then
            if skill_at project "$target"; then status FALLA "$comp" "sigue existiendo $(skill_dir project "$target")"
            else status OK "$comp" "retirada $target"; done_idx+=("$idx"); fi
          fi
        fi ;;
      mcp)
        # shellcheck disable=SC2086  # el comando guardado se separa en palabras a propósito
        if run "$comp" "quitar mcpServers.serena de .mcp.json (solo si no se modificó)" -- helper mcp-remove "$(native "$PROJ/.mcp.json")" serena $undo; then
          [ $APPLY = 1 ] && { status OK "$comp" ".mcp.json#serena retirado"; done_idx+=("$idx"); }
        else
          [ $APPLY = 1 ] && status MANUAL "$comp" "la entrada cambió después de instalarla: retirarla a mano si procede"
        fi ;;
      block)
        if run "$comp" "quitar el bloque RTK de CLAUDE.md" -- helper block-remove "$(native "$PROJ/CLAUDE.md")" "$RTK_BLOCK_START" "$RTK_BLOCK_END"; then
          [ $APPLY = 1 ] && { status OK "$comp" "bloque RTK retirado de CLAUDE.md"; done_idx+=("$idx"); }
        fi ;;
      *) status MANUAL "$comp" "($kind $target) $undo" ;;
    esac
  done
  if [ $APPLY = 1 ] && [ ${#done_idx[@]} -gt 0 ]; then
    helper state-drop "$(native "$STATE")" "${done_idx[@]}" >/dev/null
    [ -f "$STATE" ] && echo "  Quedan registros [MANUAL] en $STATE: borrarlos cuando se hayan deshecho a mano."
    # Restos vacíos que dejan el CLI de skills y el propio estado (solo si quedaron vacíos).
    if helper lock-empty "$(native "$PROJ/skills-lock.json")"; then
      rm -f "$PROJ/skills-lock.json" && status OK retiro "skills-lock.json vacío borrado"
    fi
    local dir
    for dir in "$PROJ/.claude/skills" "$PROJ/.claude" "$(dirname "$STATE")"; do
      if [ -d "$dir" ] && rmdir "$dir" 2>/dev/null; then status OK retiro "carpeta vacía borrada: $dir"; fi
    done
  fi
  return 0
}

# --------------------------------------------------------------------------- principal
echo "integrations.sh $SKILL_VERSION — modo: $MODE$([ $APPLY = 1 ] && [ "$MODE" = uninstall ] && echo ' --apply') · proyecto: $PROJ · ámbito: $SCOPE · rtk: $RTK_SCOPE · so: $OS"
echo "config de Claude Code: $CLAUDE_HOME · estado: $STATE · python: ${PY:-NO} · node: $(node --version 2>/dev/null || echo NO)"
[ -n "$PY" ] || echo "AVISO: sin Python 3, Serena, RTK, el estado y la detección de plugins quedan sin comprobar (resultado INCOMPLETO)"

if [ "$MODE" = uninstall ]; then
  uninstall_all
  echo
  [ $APPLY = 1 ] || echo "PLAN DE RETIRO: no se escribió nada. Repetir con --uninstall --apply tras la aprobación."
  [ $FAILS -eq 0 ] || { echo "resultado: $FAILS falla(s)"; exit 1; }
  [ $INCOMPLETE -eq 0 ] || exit 3
  exit 0
fi

if [ "$MODE" != check ]; then
  section "COMPONENTES"
  for c in "${ALL_COMPONENTS[@]}"; do
    if ! selected "$c"; then status "OMITIDO - NO SELECCIONADO" "$c" "(--only/--skip)"; record "$c" "OMITIDO - NO SELECCIONADO"; continue; fi
    case "$c" in
      archify) do_archify ;;
      frontend-design) do_frontend ;;
      superpowers) do_superpowers ;;
      serena) do_serena ;;
      rtk) do_rtk ;;
    esac
  done
  section "RESUMEN"
  for l in "${SUMMARY[@]}"; do echo "  $l"; done
  if [ $APPLY = 1 ] && [ -n "$PY" ]; then
    helper state-save "$(native "$STATE")" "$ONLY" "$SKIP" "$SCOPE" "$RTK_SCOPE" "$FORCE_FRONTEND" "$SKILL_VERSION"
    echo "  selección y registros guardados en $STATE (--check y --uninstall los reutilizan)"
  fi
fi

if [ "$MODE" = plan ]; then
  echo
  echo "PLAN: no se escribió nada. Revisar arriba y repetir con --apply tras la aprobación."
  [ $FAILS -eq 0 ] || { echo "Hay $FAILS falla(s)/conflicto(s) que resolver antes de aplicar."; exit 1; }
  [ $INCOMPLETE -eq 0 ] || { echo "Plan INCOMPLETO: $INCOMPLETE comprobación(es) no ejecutada(s)."; exit 3; }
  exit 0
fi

healthcheck

echo
if [ $FAILS -ne 0 ]; then
  echo "resultado: $FAILS falla(s) o conflicto(s) — ver arriba"; exit 1
elif [ $INCOMPLETE -ne 0 ]; then
  echo "resultado: INCOMPLETO — $INCOMPLETE comprobación(es) no ejecutada(s). No presentar como 'sin fallas'"; exit 3
fi
echo "resultado: sin fallas (sfp + componentes seleccionados accesibles y sin conflictos)"
exit 0
