#!/usr/bin/env bash
# ejecutar.sh: pruebas automáticas de los scripts de la skill.
#
# Uso:  bash tests/ejecutar.sh
#
# No necesita internet ni instala nada: todo se prueba en carpetas temporales que se borran al terminar.
# Requisitos: bash, git, Python 3 (3.11 o superior para las pruebas de TOML; sin él se omiten).
# Códigos de salida: 0 = todo bien, 1 = alguna prueba falló.

set -u
RAIZ=$(cd "$(dirname "$0")/.." && pwd)
SCRIPTS="$RAIZ/scripts"
export RTK_DISABLED=1

PY=""
for c in python3 python; do
  if command -v "$c" >/dev/null 2>&1 && "$c" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 8) else 1)' >/dev/null 2>&1; then PY="$c"; break; fi
done

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

PASS=0; FAIL=0; OMITIDAS=0
ok() { PASS=$((PASS + 1)); printf '  ok       %s\n' "$1"; }
falla() { FAIL=$((FAIL + 1)); printf '  FALLA    %s\n' "$1"; [ -n "${2:-}" ] && printf '           %s\n' "$2"; return 0; }
omitida() { OMITIDAS=$((OMITIDAS + 1)); printf '  omitida  %s (%s)\n' "$1" "$2"; }
seccion() { printf '\n== %s\n' "$1"; }
nativo() { if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else printf '%s\n' "$1"; fi; }

# comprobar "descripción" comando...   (pasa si el comando termina con código 0)
comprobar() { local d="$1"; shift; if "$@" >/dev/null 2>&1; then ok "$d"; else falla "$d"; fi; }
# codigo "descripción" esperado comando...   (pasa si el comando termina con ese código)
codigo() { local d="$1" esperado="$2"; shift 2; "$@" >/dev/null 2>&1; local rc=$?; if [ "$rc" = "$esperado" ]; then ok "$d"; else falla "$d" "código $rc, se esperaba $esperado"; fi; }
# contiene "descripción" "texto" archivo
contiene() { if grep -q -F -- "$2" "$3" 2>/dev/null; then ok "$1"; else falla "$1" "no aparece: $2"; fi; }
# no_contiene "descripción" "texto" archivo
no_contiene() { if grep -q -F -- "$2" "$3" 2>/dev/null; then falla "$1" "aparece: $2"; else ok "$1"; fi; }

AYUDANTE="$SCRIPTS/integrations_helpers.py"
ayudante() { PYTHONUTF8=1 "$PY" -I "$(nativo "$AYUDANTE")" "$@"; }

# --------------------------------------------------------------------------------------------
seccion "1. Sintaxis de los scripts"
for f in "$SCRIPTS"/*.sh "$SCRIPTS"/hooks/*.sh; do
  comprobar "bash -n $(basename "$f")" bash -n "$f"
done
for f in discover verify fingerprint uninstall sfp-section lib; do
  comprobar "sh -n $f.sh (POSIX)" sh -n "$SCRIPTS/$f.sh"
done
comprobar "sh -n del filtro de firmas (POSIX)" sh -n "$SCRIPTS/hooks/commit-msg-ai-attribution.sh"
if [ -n "$PY" ]; then
  for f in manifest_tool.py integrations_helpers.py; do
    comprobar "Python válido: $f" "$PY" -I -c "import ast,sys; ast.parse(open(sys.argv[1], encoding='utf-8').read())" "$(nativo "$SCRIPTS/$f")"
  done
  comprobar "el esquema del manifiesto es JSON válido" "$PY" -I -c "import json,sys; json.load(open(sys.argv[1], encoding='utf-8'))" "$(nativo "$RAIZ/references/manifest.schema.json")"
else
  omitida "validación de Python y del esquema" "no hay Python 3"
fi

# --------------------------------------------------------------------------------------------
seccion "2. Búsqueda de secciones de la metodología"
n=0; malas=""
while read -r lado num; do
  n=$((n + 1))
  sh "$SCRIPTS/sfp-section.sh" "$lado" "$num" >/dev/null 2>&1 || malas="$malas $lado-$num"
done < <(grep -oE '\b(con|sin) [0-9]+(\.[0-9]+)?' "$RAIZ/references/sfp-index.md" | sort -u)
if [ "$n" -gt 0 ] && [ -z "$malas" ]; then ok "las $n consultas del índice resuelven una sección"; else falla "consultas del índice sin resolver" "${malas:-no se encontró ninguna consulta}"; fi
codigo "una sección que no existe devuelve 1" 1 sh "$SCRIPTS/sfp-section.sh" sin 999
codigo "una variante inválida devuelve 2" 2 sh "$SCRIPTS/sfp-section.sh" otra 1

# --------------------------------------------------------------------------------------------
seccion "3. Análisis y verificación de un proyecto vacío"
mkdir -p "$TMP/vacio"
codigo "discover.sh termina bien" 0 sh "$SCRIPTS/discover.sh" "$TMP/vacio"
sh "$SCRIPTS/discover.sh" "$TMP/vacio" >"$TMP/discover.txt" 2>&1
contiene "discover.sh informa el proyecto analizado" "# Discovery" "$TMP/discover.txt"
codigo "verify.sh sin manifiesto ni git devuelve 3 (incompleto), no 0" 3 sh "$SCRIPTS/verify.sh" "$TMP/vacio"
mkdir -p "$TMP/copia-sin-git/.github/workflows"
sh "$SCRIPTS/discover.sh" "$TMP/copia-sin-git" >"$TMP/discover-copia.txt" 2>&1
contiene "discover.sh avisa una copia sin historial de un proyecto con CI de GitHub" "copia_sin_historial: posible" "$TMP/discover-copia.txt"
no_contiene "discover.sh no avisa copia sin historial en una carpeta vacía" "copia_sin_historial" "$TMP/discover.txt"
mkdir -p "$TMP/casa-asistentes/.gemini"
HOME="$TMP/casa-asistentes" sh "$SCRIPTS/discover.sh" "$TMP/vacio" >"$TMP/discover-asistentes.txt" 2>&1
if command -v gemini >/dev/null 2>&1; then omitida "asistente solo con carpeta" "gemini está instalado en este equipo"
else contiene "discover.sh marca como señal débil un asistente que solo tiene su carpeta" "Gemini CLI [debil]: carpeta ~/.gemini" "$TMP/discover-asistentes.txt"; fi
mkdir -p "$TMP/con-tests/src" "$TMP/con-tests/tests" "$TMP/con-tests/api"
: >"$TMP/con-tests/src/email.test.js"; : >"$TMP/con-tests/tests/registro.test.js"; : >"$TMP/con-tests/api/openapi.yaml"
sh "$SCRIPTS/discover.sh" "$TMP/con-tests" >"$TMP/discover-tests.txt" 2>&1
contiene "discover.sh cuenta los tests que quedan fuera de las carpetas de tests" "tests_fuera_de_carpetas_de_tests: 1" "$TMP/discover-tests.txt"
contiene "discover.sh nombra el test que está junto al código" "src/email.test.js" "$TMP/discover-tests.txt"
no_contiene "discover.sh no cuenta los tests que ya están en su carpeta" "  tests/registro.test.js" "$TMP/discover-tests.txt"
contiene "discover.sh encuentra el documento de OpenAPI" "api/openapi.yaml" "$TMP/discover-tests.txt"
mkdir -p "$TMP/con-web"; printf '{"packageManager": "bun@1.1.0", "dependencies": {"electron": "30"}}\n' >"$TMP/con-web/package.json"
sh "$SCRIPTS/discover.sh" "$TMP/con-web" >"$TMP/discover-web.txt" 2>&1
contiene "discover.sh detecta una interfaz web de escritorio (Electron)" "interfaz_web: si (package.json)" "$TMP/discover-web.txt"
contiene "discover.sh informa el gestor de paquetes del proyecto" "gestor_de_paquetes_js: bun" "$TMP/discover-web.txt"
contiene "discover.sh dice cuando no hay interfaz web" "interfaz_web: no detectada" "$TMP/discover.txt"
bash "$SCRIPTS/integrations.sh" --only archify "$TMP/con-web" >"$TMP/plan-web.txt" 2>&1
contiene "integrations.sh --runner auto mira el gestor del proyecto" "gestor del proyecto: bun" "$TMP/plan-web.txt"
mkdir -p "$TMP/con-npm"; printf '{"lockfileVersion": 3}
' >"$TMP/con-npm/package-lock.json"
bash "$SCRIPTS/integrations.sh" --only archify "$TMP/con-npm" >"$TMP/plan-npm.txt" 2>&1
contiene "un proyecto con package-lock.json se ejecuta con npm" "gestor del proyecto: npm" "$TMP/plan-npm.txt"
if command -v npm >/dev/null 2>&1; then contiene "y el CLI de skills se ejecuta con npm exec" "CLI de skills con: npm" "$TMP/plan-npm.txt"; fi

# Copia fija del skill dentro de un proyecto, más vieja que la instalación global
mkdir -p "$TMP/global-sfp" "$TMP/con-copia/herramientas/spec-first-protocol"
printf -- '---\nname: spec-first-protocol\n---\n' >"$TMP/global-sfp/SKILL.md"
printf '## 9.9.9\n' >"$TMP/global-sfp/CHANGELOG.md"
printf -- '---\r\nname: spec-first-protocol\r\n---\r\n' >"$TMP/con-copia/herramientas/spec-first-protocol/SKILL.md"
printf '## 1.0.0\n' >"$TMP/con-copia/herramientas/spec-first-protocol/CHANGELOG.md"
SFP_GLOBAL_SKILL_DIR="$TMP/global-sfp" sh "$SCRIPTS/verify.sh" "$TMP/con-copia" >"$TMP/verify-copia.txt" 2>&1
contiene "verify.sh avisa que la copia del skill en el proyecto quedó atrás" "usa la 1.0.0 y tu instalación global ya tiene la 9.9.9" "$TMP/verify-copia.txt"
sh "$SCRIPTS/verify.sh" "$TMP/vacio" >"$TMP/verify-sin-copia.txt" 2>&1
contiene "verify.sh dice cuando el proyecto no tiene copias del skill" "ninguna: el proyecto usa la instalación global" "$TMP/verify-sin-copia.txt"
contiene "verify.sh explica el código de salida y cómo tratarlo en CI" "en CI: tratar 3 como advertencia" "$TMP/verify-sin-copia.txt"
codigo "verify.sh --strict-tooling convierte lo incompleto en falla (1)" 1 sh "$SCRIPTS/verify.sh" --strict-tooling "$TMP/vacio"

# Filtro de firmas versionado: debe estar activo en cada copia del repositorio
if command -v git >/dev/null 2>&1; then
  H="$TMP/con-filtro"; mkdir -p "$H/.githooks"
  git -C "$H" init -q
  { printf '#!/bin/sh\n'; sed -n '/^# sfp:start/,/^# sfp:end/p' "$SCRIPTS/hooks/commit-msg-ai-attribution.sh"; } >"$H/.githooks/commit-msg"
  chmod +x "$H/.githooks/commit-msg"
  sh "$SCRIPTS/verify.sh" "$H" >"$TMP/verify-filtro.txt" 2>&1; rc=$?
  [ "$rc" = 1 ] && ok "verify.sh falla si el filtro versionado no está activo en esta copia" || falla "verify.sh con el filtro inactivo devolvió $rc"
  contiene "verify.sh dice cómo activar el filtro en esta copia" "git config core.hooksPath .githooks" "$TMP/verify-filtro.txt"
  git -C "$H" config core.hooksPath .githooks
  sh "$SCRIPTS/verify.sh" "$H" >"$TMP/verify-filtro.txt" 2>&1
  contiene "verify.sh reconoce el filtro activo" "ok: activo en esta copia" "$TMP/verify-filtro.txt"
  L="$TMP/filtro-local"; mkdir -p "$L"; git -C "$L" init -q
  cp "$H/.githooks/commit-msg" "$L/.git/hooks/commit-msg"
  sh "$SCRIPTS/verify.sh" "$L" >"$TMP/verify-local.txt" 2>&1
  contiene "verify.sh avisa que un filtro solo en .git/hooks no viaja al clonar" "no se versiona y no llega a quien clone" "$TMP/verify-local.txt"
  # Una copia del skill dentro del proyecto no se confunde con el filtro (sus scripts lo mencionan)
  V="$TMP/con-skill-copiado"; mkdir -p "$V/.claude/skills"; git -C "$V" init -q
  mkdir -p "$V/.claude/skills/spec-first-protocol"
  cp -R "$RAIZ/scripts" "$RAIZ/SKILL.md" "$RAIZ/CHANGELOG.md" "$V/.claude/skills/spec-first-protocol/"
  sh "$SCRIPTS/verify.sh" "$V" >"$TMP/verify-copiado.txt" 2>&1
  contiene "una copia del skill en el proyecto no cuenta como filtro instalado" "no se usa el filtro en este proyecto" "$TMP/verify-copiado.txt"
else
  omitida "filtro de firmas en cada copia" "no hay git"
fi
# Sin la variable HOME (cron, contenedores), verify.sh no debe abortar
( unset HOME; sh "$SCRIPTS/verify.sh" "$TMP/vacio" >/dev/null 2>&1 ); rc=$?
[ "$rc" = 3 ] && ok "verify.sh funciona sin la variable HOME" || falla "verify.sh sin HOME devolvió $rc"

# --------------------------------------------------------------------------------------------
seccion "4. Ciclo completo: instalar con huellas, verificar, editar y retirar"
if [ -z "$PY" ] || ! command -v git >/dev/null 2>&1; then
  omitida "ciclo del manifiesto" "hace falta git y Python 3"
else
  P="$TMP/proyecto"; mkdir -p "$P" && cd "$P" || exit 1
  git init -q . && git config user.name prueba && git config user.email prueba@example.com
  printf '# Proyecto de prueba\n' >INSTRUCCIONES.md
  git add -A && git commit -q -m base && git tag pre-sfp
  # Se simula la fase de aplicación: un bloque con marcadores y un archivo nuevo
  printf '\n<!-- sfp:start v1 id=1 -->\n## Metodología\nSe trabaja con especificaciones.\n<!-- sfp:end id=1 -->\n' >>INSTRUCCIONES.md
  mkdir -p docs/adr && printf '# 0001. Decisión de ejemplo\n\n- Status: aceptado\n' >docs/adr/0001-ejemplo.md
  mkdir -p .sfp
  VERSION=$(sed -n 's/^## \([0-9][0-9.]*\).*/\1/p' "$RAIZ/CHANGELOG.md" | head -1)
  cat >.sfp/manifest.json <<EOF
{"schema": 2, "tool": "project-setup", "skill_version": "$VERSION", "installed_at": "2026-01-01",
 "source_methodology": {"variant": "sin-orquestador", "methodology": "SFP", "version_or_hash": "PENDIENTE"},
 "classification": {"project_state": "existente", "intrusion": "integrar", "orchestration": "none"},
 "runtimes": ["generico"], "backup": {"type": "git-tag", "ref": "pre-sfp"},
 "actions": [
  {"id": 1, "type": "merge", "path": "INSTRUCCIONES.md", "markers": true, "risk": "bajo", "reversible": true, "note": "punto de entrada"},
  {"id": 2, "type": "create", "path": "docs/adr/0001-ejemplo.md", "risk": "bajo", "reversible": true, "note": "decisión de ejemplo"}
 ]}
EOF
  codigo "fingerprint.sh --propose calcula las huellas" 0 sh "$SCRIPTS/fingerprint.sh" --propose .
  comprobar "la propuesta de manifiesto se escribió" test -f .sfp/manifest.proposed.json
  codigo "fingerprint.sh --accept acepta la propuesta" 0 sh "$SCRIPTS/fingerprint.sh" --accept .
  contiene "el manifiesto aceptado lleva huellas sha256" '"sha256"' .sfp/manifest.json
  codigo "verify.sh sin fallas devuelve 0" 0 sh "$SCRIPTS/verify.sh" .
  # El usuario edita después el archivo creado por el setup
  printf '\nNota añadida por una persona después de la instalación.\n' >>docs/adr/0001-ejemplo.md
  sh "$SCRIPTS/uninstall.sh" . >"$TMP/retiro-simulado.txt" 2>&1
  contiene "el retiro simulado quitaría el bloque sin cambios (AUTO)" "[AUTO]" "$TMP/retiro-simulado.txt"
  contiene "el retiro simulado deja a decisión humana lo que se editó (MANUAL)" "[MANUAL]" "$TMP/retiro-simulado.txt"
  comprobar "el retiro simulado no escribió nada" test -f docs/adr/0001-ejemplo.md
  codigo "uninstall.sh --apply deja lo editado a decisión humana (código 3)" 3 sh "$SCRIPTS/uninstall.sh" --apply .
  no_contiene "el bloque con marcadores se quitó de INSTRUCCIONES.md" "sfp:start" INSTRUCCIONES.md
  contiene "el contenido propio del archivo se conservó" "# Proyecto de prueba" INSTRUCCIONES.md
  comprobar "el archivo editado por una persona se conservó" test -f docs/adr/0001-ejemplo.md
  cd "$RAIZ" || exit 1
fi

# --------------------------------------------------------------------------------------------
seccion "4b. Proyecto de ejemplo"
EJ="$RAIZ/examples/proyecto-con-sfp"
if [ -n "$PY" ]; then
  codigo "el manifiesto del ejemplo cumple el esquema" 0 "$PY" -I "$(nativo "$SCRIPTS/manifest_tool.py")" check "$(nativo "$EJ/.sfp/manifest.json")"
  codigo "verify.sh sobre el ejemplo no encuentra fallas (puede quedar incompleto sin git)" 3 sh "$SCRIPTS/verify.sh" "$EJ"
  if command -v git >/dev/null 2>&1 && git -C "$EJ" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    sh "$SCRIPTS/verify.sh" "$EJ" >"$TMP/verify-ejemplo.txt" 2>&1
    contiene "el filtro del ejemplo, dentro de otro repositorio, se informa como no comprobado" "dentro de otro repositorio" "$TMP/verify-ejemplo.txt"
  fi
  printf 'Asunto\n\nCo-Authored-By: Claude <noreply@anthropic.com>\n' >"$TMP/msg-ejemplo.txt"
  sh "$EJ/.githooks/commit-msg" "$TMP/msg-ejemplo.txt"
  no_contiene "el filtro versionado del ejemplo quita la firma de un asistente" "anthropic" "$TMP/msg-ejemplo.txt"
else
  omitida "proyecto de ejemplo" "no hay Python 3"
fi
if command -v node >/dev/null 2>&1; then
  (cd "$EJ" && node --test) >/dev/null 2>&1 && ok "las pruebas del código del ejemplo pasan" || falla "las pruebas del código del ejemplo fallan"
else
  omitida "pruebas del código del ejemplo" "no hay Node.js"
fi

# --------------------------------------------------------------------------------------------
seccion "5. Filtro de firmas de asistentes de IA en los commits"
HOOK="$SCRIPTS/hooks/commit-msg-ai-attribution.sh"
mensaje() { printf '%s\n' "$@" >"$TMP/msg.txt"; sh "$HOOK" "$TMP/msg.txt"; }
mensaje "Asunto" "" "Co-Authored-By: Claude Opus <noreply@anthropic.com>" "Co-authored-by: Persona <persona@example.com>"
no_contiene "quita la firma de un asistente de IA" "anthropic" "$TMP/msg.txt"
contiene "conserva a una persona como coautora" "persona@example.com" "$TMP/msg.txt"
mensaje "Asunto" "" "Co-authored-by: Copilot <198982749+Copilot@users.noreply.github.com>" "Generated with un asistente"
no_contiene "quita la firma de Copilot" "Copilot" "$TMP/msg.txt"
mensaje "Asunto" "" "Co-authored-by: Jules Pérez <jules@empresa.com>" "Signed-off-by: Ana <ana@example.com>"
contiene "no confunde a una persona llamada Jules con el asistente" "jules@empresa.com" "$TMP/msg.txt"
contiene "conserva Signed-off-by" "Signed-off-by" "$TMP/msg.txt"
mensaje "Claude: el asunto no se toca" "" "Cuerpo normal."
contiene "no modifica el asunto" "Claude: el asunto no se toca" "$TMP/msg.txt"
printf 'Asunto\n\nCo-Authored-By: Claude <noreply@anthropic.com>\n' >"$TMP/msg.txt"
SFP_KEEP_AI_ATTRIBUTION=1 sh "$HOOK" "$TMP/msg.txt"
contiene "SFP_KEEP_AI_ATTRIBUTION=1 conserva la firma" "anthropic" "$TMP/msg.txt"

# --------------------------------------------------------------------------------------------
seccion "6. Ayudantes de configuración (JSON, TOML, bloques y estado)"
if [ -z "$PY" ]; then
  omitida "ayudantes de configuración" "no hay Python 3"
else
  # MCP: añadir sin tocar lo ajeno, y quitar solo si no se modificó
  printf '{\n    "mcpServers": {\n        "otro": {"command": "x"}\n    }\n}\n' >"$TMP/mcp.json"
  M=$(nativo "$TMP/mcp.json")
  codigo "mcp-add añade una entrada" 0 ayudante mcp-add "$M" serena uvx -p 3.13 serena
  contiene "mcp-add conserva las entradas ajenas" '"otro"' "$TMP/mcp.json"
  contiene "mcp-add conserva la sangría del archivo" '        "serena"' "$TMP/mcp.json"
  codigo "mcp-add es idempotente" 0 ayudante mcp-add "$M" serena uvx -p 3.13 serena
  [ "$(grep -c '"serena": {' "$TMP/mcp.json")" = 1 ] && ok "mcp-add no duplica la entrada" || falla "mcp-add duplicó la entrada"
  codigo "mcp-remove no toca una entrada que cambió" 1 ayudante mcp-remove "$M" serena uvx -p 3.12 serena
  codigo "mcp-remove quita la entrada exacta" 0 ayudante mcp-remove "$M" serena uvx -p 3.13 serena
  no_contiene "mcp-remove dejó el archivo sin la entrada" '"serena"' "$TMP/mcp.json"
  contiene "mcp-remove conservó las entradas ajenas" '"otro"' "$TMP/mcp.json"

  # Bloques de texto entre marcas
  printf 'Línea propia\n<!-- rtk-instructions v2 -->\nbloque\n<!-- /rtk-instructions -->\n' >"$TMP/claude.md"
  C=$(nativo "$TMP/claude.md")
  codigo "block-has detecta el bloque" 0 ayudante block-has "$C" "<!-- rtk-instructions"
  codigo "block-remove quita el bloque" 0 ayudante block-remove "$C" "<!-- rtk-instructions" "<!-- /rtk-instructions -->"
  no_contiene "el bloque desapareció" "rtk-instructions" "$TMP/claude.md"
  contiene "la línea propia se conservó" "Línea propia" "$TMP/claude.md"

  # Estado de las integraciones
  S=$(nativo "$TMP/estado.json")
  codigo "state-add registra una instalación" 0 ayudante state-add "$S" archify project skill 1 archify "npx remove archify"
  codigo "state-add es idempotente" 0 ayudante state-add "$S" archify project skill 1 archify "npx remove archify"
  [ "$(ayudante state-list "$S" | wc -l | tr -d ' ')" = 1 ] && ok "el estado tiene un solo registro" || falla "el estado duplicó el registro"
  codigo "state-save guarda la selección" 0 ayudante state-save "$S" "" "rtk" project global 0 1.0.0
  ayudante state-select "$S" >"$TMP/seleccion.txt"
  contiene "state-select devuelve lo guardado" "skip=rtk" "$TMP/seleccion.txt"
  contiene "un estado anterior sin asistente se lee como claude-code" "agent=claude-code" "$TMP/seleccion.txt"
  codigo "state-save guarda el asistente y el gestor de paquetes" 0 ayudante state-save "$S" "" "rtk" project global 0 1.0.0 codex pnpm
  ayudante state-select "$S" >"$TMP/seleccion.txt"
  contiene "state-select devuelve el asistente guardado" "agent=codex" "$TMP/seleccion.txt"
  contiene "state-select devuelve el gestor guardado" "runner=pnpm" "$TMP/seleccion.txt"
  contiene "un estado nuevo no se marca como anterior a 1.15.0" "legacy=0" "$TMP/seleccion.txt"
  printf '{"tool": "spec-first-protocol/integrations.sh", "records": [], "selection": {"only": "", "skip": "", "scope": "project", "rtk_scope": "global"}}\n' >"$TMP/estado-viejo.json"
  ayudante state-select "$(nativo "$TMP/estado-viejo.json")" >"$TMP/seleccion-vieja.txt" 2>&1
  contiene "un estado anterior a 1.15.0 se reconoce (sus componentes nuevos no se exigen)" "legacy=1" "$TMP/seleccion-vieja.txt"
  codigo "state-drop quita el registro" 0 ayudante state-drop "$S" 0
  comprobar "sin registros, el estado se borra" test ! -f "$TMP/estado.json"

  # TOML: requiere Python 3.11 o superior
  if "$PY" -c 'import tomllib' >/dev/null 2>&1; then
    printf '[telemetry]\nenabled = false\n\n[hooks]\n# propias\nexclude_commands = [\n  "git rebase",  # comentario con ] corchete\n  "^curl",\n]\nsuppress_hook_warning = true\n' >"$TMP/config.toml"
    T=$(nativo "$TMP/config.toml")
    codigo "toml-list apply añade valores" 0 ayudante toml-list apply "$T" hooks exclude_commands '^sh .*sfp' '^py .*sfp'
    contiene "toml-list conserva los valores propios" "git rebase" "$TMP/config.toml"
    contiene "toml-list conserva otras claves de la misma tabla" "suppress_hook_warning = true" "$TMP/config.toml"
    contiene "toml-list conserva otras tablas" "[telemetry]" "$TMP/config.toml"
    codigo "toml-list check confirma que están" 0 ayudante toml-list check "$T" hooks exclude_commands '^sh .*sfp'
    codigo "toml-list remove quita solo lo propio de la skill" 0 ayudante toml-list remove "$T" hooks exclude_commands '^sh .*sfp' '^py .*sfp'
    no_contiene "toml-list remove dejó el archivo sin esos valores" "sfp" "$TMP/config.toml"
    contiene "toml-list remove conservó los valores del usuario" "^curl" "$TMP/config.toml"
  else
    omitida "pruebas de TOML" "hace falta Python 3.11 o superior"
  fi
fi

# --------------------------------------------------------------------------------------------
seccion "7. Instalador de herramientas complementarias (sin red)"
codigo "integrations.sh --help termina bien" 0 bash "$SCRIPTS/integrations.sh" --help
codigo "una opción desconocida devuelve 2" 2 bash "$SCRIPTS/integrations.sh" --opcion-inexistente
codigo "un ámbito inválido devuelve 2" 2 bash "$SCRIPTS/integrations.sh" --scope otro
codigo "un componente desconocido devuelve 2" 2 bash "$SCRIPTS/integrations.sh" --only nada
codigo "--check y --uninstall no se pueden combinar" 2 bash "$SCRIPTS/integrations.sh" --check --uninstall
codigo "un asistente desconocido devuelve 2" 2 bash "$SCRIPTS/integrations.sh" --agent otro
codigo "un gestor de paquetes desconocido devuelve 2" 2 bash "$SCRIPTS/integrations.sh" --runner otro
# Plan para Codex, con una carpeta personal vacía para no depender de lo instalado en este equipo
PO="$TMP/proyecto-codex"; mkdir -p "$PO/.claude/skills/archify" "$TMP/casa"
printf -- '---\nname: archify\n---\n' >"$PO/.claude/skills/archify/SKILL.md"
HOME="$TMP/casa" CLAUDE_CONFIG_DIR="$TMP/casa/.claude" CODEX_HOME="$TMP/casa/.codex" \
  bash "$SCRIPTS/integrations.sh" --agent codex --only archify,modern-web-guidance,serena,rtk "$PO" >"$TMP/plan-codex.txt" 2>&1
contiene "Codex guarda su estado aparte" "integrations-codex.json" "$TMP/plan-codex.txt"
contiene "Codex no da por instalada una skill que solo está en .claude/skills (Codex no la lee)" "instalar archify" "$TMP/plan-codex.txt"
contiene "Serena en Codex se planifica en .codex/config.toml" ".codex/config.toml ([mcp_servers.serena])" "$TMP/plan-codex.txt"
contiene "RTK en Codex se planifica con su hook" "rtk init -g --codex" "$TMP/plan-codex.txt"
contiene "modern-web-guidance no se ofrece sin interfaz web" "OMITIDO - SIN FRONTEND" "$TMP/plan-codex.txt"
comprobar "el plan para Codex no escribió nada" test ! -e "$PO/.sfp" -a ! -e "$PO/.codex"

# Retiro en Codex con un npx simulado (sin red): .agents/skills es compartida y el CLI solo la borra sin --agent
if [ -n "$PY" ] && command -v node >/dev/null 2>&1; then
  FALSO="$TMP/npx-simulado"; mkdir -p "$FALSO"
  cat >"$FALSO/npx" <<'NPX'
#!/bin/sh
printf '%s\n' "$*" >>"$NPX_REGISTRO"
case " $* " in *" remove "*) for a in "$@"; do [ -d ".agents/skills/$a" ] && rm -rf ".agents/skills/$a"; done ;; esac
exit 0
NPX
  chmod +x "$FALSO/npx"
  for caso in solo-codex con-copia-claude; do
    PR="$TMP/retiro-$caso"; mkdir -p "$PR/.agents/skills/archify" "$PR/.sfp"
    printf -- '---\nname: archify\n---\n' >"$PR/.agents/skills/archify/SKILL.md"
    if [ "$caso" = con-copia-claude ]; then mkdir -p "$PR/.claude/skills"; cp -R "$PR/.agents/skills/archify" "$PR/.claude/skills/"; fi
    EO="$(nativo "$PR/.sfp/integrations-codex.json")"
    ayudante state-save "$EO" "archify" "" project global 0 1.15.0 codex npx >/dev/null 2>&1
    ayudante state-add "$EO" archify project skill 1 archify "npx -y skills@1.9.0 remove -y archify" >/dev/null 2>&1
    : >"$TMP/registro-npx-$caso.txt"
    PATH="$FALSO:$PATH" NPX_REGISTRO="$TMP/registro-npx-$caso.txt" HOME="$TMP/casa" CLAUDE_CONFIG_DIR="$TMP/casa/.claude" CODEX_HOME="$TMP/casa/.codex" \
      bash "$SCRIPTS/integrations.sh" --uninstall --apply --agent codex "$PR" >"$TMP/retiro-$caso.txt" 2>&1
  done
  contiene "Codex: el retiro llama al CLI sin --agent" "remove archify -y" "$TMP/registro-npx-solo-codex.txt"
  no_contiene "Codex: el retiro no usa --agent codex (el CLI no borraría la carpeta compartida)" "--agent" "$TMP/registro-npx-solo-codex.txt"
  comprobar "Codex: la skill retirada ya no está en .agents/skills" test ! -e "$TMP/retiro-solo-codex/.agents/skills/archify"
  contiene "Codex: con una copia de Claude Code, el retiro queda a decisión humana" "también está en .claude/skills" "$TMP/retiro-con-copia-claude.txt"
  comprobar "Codex: con una copia de Claude Code no se llama al CLI" test ! -s "$TMP/registro-npx-con-copia-claude.txt"
  comprobar "Codex: la copia de Claude Code se conserva" test -f "$TMP/retiro-con-copia-claude/.claude/skills/archify/SKILL.md"
else
  omitida "retiro en Codex con npx simulado" "hace falta Python 3 y Node.js"
fi

# Context7 en el config.toml de Codex (requiere Python 3.11 para TOML y Node.js 20.18.1)
if [ -n "$PY" ] && "$PY" -c 'import tomllib' >/dev/null 2>&1 && command -v node >/dev/null 2>&1 \
   && node -e 'const [a,b]=process.versions.node.split(".").map(Number);process.exit(a>20||(a===20&&b>=18)?0:1)'; then
  PC="$TMP/context7-codex"; mkdir -p "$PC"
  HOME="$TMP/casa" CLAUDE_CONFIG_DIR="$TMP/casa/.claude" CODEX_HOME="$TMP/casa/.codex" \
    bash "$SCRIPTS/integrations.sh" --apply --agent codex --only context7 "$PC" >"$TMP/context7-codex.txt" 2>&1
  contiene "Context7 en Codex va a [mcp_servers.context7]" "[mcp_servers.context7]" "$PC/.codex/config.toml"
  contiene "Context7 queda con la versión fijada" "@upstash/context7-mcp@4.9.0" "$PC/.codex/config.toml"
  contiene "Context7 en Codex lleva el tiempo de arranque que recomienda su documentación" "startup_timeout_sec = 20" "$PC/.codex/config.toml"
  no_contiene "Context7 no escribe ninguna clave" "api-key" "$PC/.codex/config.toml"
  contiene "se avisa que Codex solo lee la configuración del proyecto si es de confianza" "de confianza" "$TMP/context7-codex.txt"
  HOME="$TMP/casa" CLAUDE_CONFIG_DIR="$TMP/casa/.claude" CODEX_HOME="$TMP/casa/.codex" \
    bash "$SCRIPTS/integrations.sh" --uninstall --apply --agent codex "$PC" >/dev/null 2>&1
  comprobar "el retiro quita la entrada y la carpeta .codex que quedó vacía" test ! -e "$PC/.codex"
  PT="$TMP/toml-propio"; mkdir -p "$PT/.codex"
  printf '# configuración propia\nmodel = "x"\n' >"$PT/.codex/config.toml"
  HOME="$TMP/casa" CLAUDE_CONFIG_DIR="$TMP/casa/.claude" CODEX_HOME="$TMP/casa/.codex" \
    bash "$SCRIPTS/integrations.sh" --apply --agent codex --only context7 "$PT" >/dev/null 2>&1
  contiene "se conservan los comentarios propios de config.toml" "# configuración propia" "$PT/.codex/config.toml"
  HOME="$TMP/casa" CLAUDE_CONFIG_DIR="$TMP/casa/.claude" CODEX_HOME="$TMP/casa/.codex" \
    bash "$SCRIPTS/integrations.sh" --uninstall --apply --agent codex "$PT" >/dev/null 2>&1
  contiene "el retiro deja la configuración propia" 'model = "x"' "$PT/.codex/config.toml"
  no_contiene "el retiro quitó la entrada de Context7" "context7" "$PT/.codex/config.toml"
  PI="$TMP/toml-invalido"; mkdir -p "$PI/.codex"; printf 'esto no es = = toml\n' >"$PI/.codex/config.toml"
  HOME="$TMP/casa" CLAUDE_CONFIG_DIR="$TMP/casa/.claude" CODEX_HOME="$TMP/casa/.codex" \
    bash "$SCRIPTS/integrations.sh" --agent codex --only context7 "$PI" >"$TMP/toml-invalido.txt" 2>&1
  contiene "un config.toml inválido no se toca" "no es TOML válido" "$TMP/toml-invalido.txt"
else
  omitida "Context7 en Codex" "hace falta Python 3.11 y Node.js 20.18.1 o superior"
fi
if [ -n "$PY" ]; then
  mkdir -p "$TMP/proyecto-integraciones/.sfp"
  PI="$TMP/proyecto-integraciones"
  ayudante state-save "$(nativo "$PI/.sfp/integrations.json")" "" "" project global 0 1.0.0 >/dev/null 2>&1
  ayudante state-add "$(nativo "$PI/.sfp/integrations.json")" archify project skill 1 archify "npx remove archify" >/dev/null 2>&1
  bash "$SCRIPTS/integrations.sh" --uninstall "$PI" >"$TMP/plan-retiro.txt" 2>&1
  rc=$?
  [ "$rc" = 0 ] && ok "--uninstall (plan) termina bien" || falla "--uninstall (plan) devolvió $rc"
  contiene "el plan de retiro nombra lo que retiraría" "retirar la skill archify" "$TMP/plan-retiro.txt"
  comprobar "el plan de retiro no borró el estado" test -f "$PI/.sfp/integrations.json"
else
  omitida "plan de retiro de integraciones" "no hay Python 3"
fi

# --------------------------------------------------------------------------------------------
printf '\n== Resumen: %s bien, %s fallaron, %s omitidas\n' "$PASS" "$FAIL" "$OMITIDAS"
[ "$FAIL" -eq 0 ]
