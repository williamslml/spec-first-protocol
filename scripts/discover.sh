#!/bin/sh
# discover.sh — inventario determinístico y de SOLO LECTURA de un proyecto.
# Uso: sh discover.sh [ruta-del-proyecto] [--global ruta-metodologia-global]
# Garantías: no escribe, no borra, no usa red, no imprime contenido de secretos
# (solo rutas). POSIX sh. Salida: secciones "## nombre" con líneas "clave: valor".
# Las listas de convenciones conocidas NO son exhaustivas: la sección
# "dotfiles-en-raiz" lista todo lo oculto para detectar herramientas no previstas.
# La sección "estructura-de-codigo" da las cifras que usa references/project-structure.md sección 3
# (features, capas, convención de framework, desplegables): no se cuentan a mano.

set -u
PROJECT="."
GLOBAL_HINT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --global) shift; GLOBAL_HINT="${1:-}";;
    -h|--help) sed -n '2,8p' "$0"; exit 0;;
    *) PROJECT="$1";;
  esac
  shift
done

if [ ! -d "$PROJECT" ]; then
  echo "ERROR: no existe el directorio: $PROJECT" >&2
  exit 2
fi
cd "$PROJECT" || exit 2
ROOT=$(pwd)

PRUNE='-name .git -o -name node_modules -o -name vendor -o -name dist -o -name build -o -name target -o -name .venv -o -name venv -o -name __pycache__ -o -name .next -o -name .nuxt -o -name .gradle -o -name .tox -o -name .terraform -o -name Pods -o -name .cache'

have() { command -v "$1" >/dev/null 2>&1; }
# grep_files <opciones de grep> <patrón> → archivos (./ruta) que contienen el patrón, sin dirs ignorados.
# Portátil a propósito: el grep de BusyBox (Alpine) no admite --exclude-dir ni -I.
grep_files() { find . \( $PRUNE \) -prune -o -type f -exec grep -l "$@" {} + 2>/dev/null | LC_ALL=C sort; }
# lista de archivos (sin dirs ignorados), profundidad máxima configurable
files_d() { # $1 = maxdepth
  # shellcheck disable=SC2086
  find . -maxdepth "$1" \( $PRUNE \) -prune -o -type f -print 2>/dev/null
}
exists_any() { # imprime las rutas existentes de la lista
  for p in "$@"; do [ -e "$p" ] && echo "  presente: $p"; done
}
section() { printf '\n## %s\n' "$1"; }
count_subdirs() { # subcarpetas visibles inmediatas de $1
  find "$1" -mindepth 1 -maxdepth 1 -type d ! -name '.*' 2>/dev/null | wc -l | tr -d ' '
}
manifests_in() { # manifiestos/archivos de build presentes directamente en $1 (uno por línea)
  for m in package.json go.mod pyproject.toml requirements.txt Cargo.toml pom.xml build.gradle build.gradle.kts Gemfile composer.json pubspec.yaml mix.exs Dockerfile; do
    [ -f "$1/$m" ] && echo "$m"
  done
  find "$1" -mindepth 1 -maxdepth 1 -type f -name '*.csproj' 2>/dev/null | sed 's#.*/##'
}
# nombres de carpeta que indican organización por capa técnica (project-structure.md sección 0)
# Se compara sin distinguir mayúsculas (.NET usa Controllers/, Models/). Incluye español y portugués.
LAYER_RE='^(controllers?|controladores?|services?|servicios?|servicos?|serviços?|models?|modelos?|repositor(y|ies)|repositorios?|repositórios?|routes?|rutas?|rotas?|routers?|handlers?|manejadores?|views?|vistas?|dtos?|entities|entity|entidades?|middlewares?|resolvers?|daos?|mappers?|mapeadores?)$'
# Carpetas que agrupan features/módulos (tampoco distinguen mayúsculas)
FEAT_RE='^(features|modules|modulos|módulos|funcionalidades)$'
# raiz_efectiva <dir> → baja por src/main/<java|kotlin|scala|groovy> y por cadenas de una sola
# subcarpeta sin archivos (paquetes com/empresa/app), sin entrar nunca en una carpeta de features o de capa
raiz_efectiva() {
  _r=$1; _i=0
  [ -d "$_r/main" ] && _r="$_r/main"
  for _l in java kotlin scala groovy; do [ -d "$_r/$_l" ] && { _r="$_r/$_l"; break; }; done
  while [ "$_i" -lt 8 ]; do
    _sub=$(find "$_r" -mindepth 1 -maxdepth 1 -type d ! -name '.*' 2>/dev/null)
    [ "$(printf '%s' "$_sub" | grep -c .)" -eq 1 ] || break
    [ -z "$(find "$_r" -mindepth 1 -maxdepth 1 -type f ! -name '.gitkeep' 2>/dev/null)" ] || break
    printf '%s\n' "${_sub##*/}" | grep -qiE "$FEAT_RE|$LAYER_RE" && break
    _r=$_sub; _i=$((_i + 1))
  done
  printf '%s' "$_r"
}

echo "# Discovery — spec-first-protocol"
section "meta"
echo "ruta: $ROOT"
echo "fecha: $(date '+%Y-%m-%d %H:%M:%S %z' 2>/dev/null || echo desconocida)"
echo "so: $(uname -sr 2>/dev/null || echo desconocido)"
echo "escritura_en_raiz: $([ -w . ] && echo si || echo no)"
printf 'herramientas_disponibles:'
for t in git node npm pnpm yarn bun python3 pip go cargo java mvn gradle dotnet ruby php docker make tmux jq; do
  have "$t" && printf ' %s' "$t"
done
# En Windows Python 3 suele llamarse solo `python`: se informa si es versión 3 y no hay python3.
if ! have python3 && have python && python -c 'import sys; sys.exit(0 if sys.version_info[0] == 3 else 1)' >/dev/null 2>&1; then
  printf ' python'
fi
echo

section "git"
if have git && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  TOP=$(git rev-parse --show-toplevel 2>/dev/null)
  echo "repo: si"
  echo "toplevel: $TOP"
  [ "$TOP" != "$ROOT" ] && echo "nota: la ruta analizada es un subdirectorio del repo (posible monorepo)"
  echo "rama: $(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
  echo "commits: $(git rev-list --count HEAD 2>/dev/null || echo 0)"
  echo "ultimo_commit: $(git log -1 --format='%cs' 2>/dev/null || echo n/a)"
  echo "cambios_sin_commitear: $(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  # URL del remoto sin credenciales embebidas
  git remote -v 2>/dev/null | awk '{print $1" "$2}' | sort -u | sed -E 's#(://)[^/@]*@#\1***@#' | sed 's/^/remoto: /'
  [ -z "$(git remote 2>/dev/null)" ] && echo "remoto: ninguno"
  # Credenciales dentro de la URL de un remote (https://usuario:token@…): solo se informa cuántas, nunca el valor.
  NCRED=$(git remote -v 2>/dev/null | awk '{print $2}' | sort -u | grep -Eic '^https?://[^/@]+@' || true)
  [ "${NCRED:-0}" -gt 0 ] && echo "remoto_con_credenciales: si ($NCRED) — la URL guarda un usuario o token en texto plano; ver git-practices.md sección 6"
  echo "tag_pre_ai_setup: $(git tag -l 'pre-sfp*' 2>/dev/null | tr '\n' ' ')"
  echo "worktrees_adicionales: $(( $(git worktree list 2>/dev/null | wc -l | tr -d ' ') - 1 ))"
  [ -f .gitmodules ] && echo "submodulos: si (.gitmodules)"
  GH=$(git rev-parse --git-path hooks 2>/dev/null)
  if [ -n "$GH" ] && [ -d "$GH" ]; then
    H=$(ls "$GH" 2>/dev/null | grep -v '\.sample$' | tr '\n' ' ')
    echo "hooks_activos: ${H:-ninguno}"
  fi
  exists_any .husky .pre-commit-config.yaml lefthook.yml .lefthook.yml
else
  echo "repo: no"
  # Señales de que el proyecto sí vive en un repositorio y esta carpeta es una copia sin historial (p. ej. un ZIP)
  SG=""
  for p in .github/workflows .gitlab-ci.yml .gitignore .gitattributes .github/CODEOWNERS; do [ -e "$p" ] && SG="$SG $p"; done
  if [ -n "$SG" ]; then
    echo "copia_sin_historial: posible (hay${SG}, pero no .git): probablemente el proyecto vive en un repositorio y esta carpeta es una copia; preguntar y recomendar trabajar sobre un clon, para que el respaldo sea una rama"
  else
    echo "advertencia: sin git no hay respaldo ni diff; proponer git init o copia manual"
  fi
fi

section "tamano-y-estructura"
NFILES=$(files_d 12 | wc -l | tr -d ' ')
echo "archivos (sin dirs ignorados, prof<=12): $NFILES"
[ "$NFILES" -gt 20000 ] && echo "nota: repo grande, tratar el discovery como parcial"
echo "directorios_nivel_1:"
find . -maxdepth 1 -mindepth 1 \( $PRUNE \) -prune -o -type d -print 2>/dev/null | sed 's#^\./##' | sort | sed 's/^/  /'
echo "archivos_nivel_1:"
find . -maxdepth 1 -mindepth 1 -type f 2>/dev/null | sed 's#^\./##' | sort | sed 's/^/  /'
echo "dotfiles-en-raiz (todo lo oculto; detecta herramientas no previstas):"
find . -maxdepth 1 -mindepth 1 -name '.*' ! -name .git 2>/dev/null | sed 's#^\./##' | sort | sed 's/^/  /'
echo "symlinks: $(find . -maxdepth 6 \( $PRUNE \) -prune -o -type l -print 2>/dev/null | wc -l | tr -d ' ')"
echo "archivos_mayores_5MB:"
find . \( $PRUNE \) -prune -o -type f -size +5M -print 2>/dev/null | head -10 | sed 's/^/  /'

section "stack"
echo "manifiestos_detectados (prof<=3):"
files_d 3 | sed 's#^\./##' | awk -F/ '{print $NF" "$0}' | awk '
  $1=="package.json"||$1=="pnpm-lock.yaml"||$1=="yarn.lock"||$1=="package-lock.json"||$1=="bun.lockb"||$1=="bun.lock"||
  $1=="pyproject.toml"||$1=="requirements.txt"||$1=="Pipfile"||$1=="poetry.lock"||$1=="setup.py"||$1=="uv.lock"||
  $1=="go.mod"||$1=="go.work"||$1=="Cargo.toml"||$1=="Cargo.lock"||$1=="pom.xml"||$1=="build.gradle"||$1=="build.gradle.kts"||$1=="settings.gradle"||
  $1=="composer.json"||$1=="Gemfile"||$1=="mix.exs"||$1=="pubspec.yaml"||$1=="Package.swift"||$1=="CMakeLists.txt"||
  $1=="Dockerfile"||$1=="docker-compose.yml"||$1=="docker-compose.yaml"||$1=="compose.yaml"||$1=="Makefile"||$1=="justfile"||$1=="Taskfile.yml"||
  $1 ~ /\.csproj$/||$1 ~ /\.sln$/||$1 ~ /\.tf$/ {print "  "$2}' | sort | head -60
echo "extensiones_mas_frecuentes:"
files_d 12 | sed -n 's/.*\.\([A-Za-z0-9]\{1,6\}\)$/\1/p' | sort | uniq -c | sort -rn | head -8 | awk '{print "  "$2" ("$1")"}'
if [ -f package.json ]; then
  echo "package.json_scripts:"
  if have jq; then jq -r '.scripts // {} | keys[]' package.json 2>/dev/null | sed 's/^/  /'
  else awk '/"scripts"[[:space:]]*:/{f=1;next} f&&/}/{f=0} f' package.json | sed -n 's/^[[:space:]]*"\([^"]*\)".*/  \1/p'
  fi
fi

# Interfaz web y gestor de paquetes (para ofrecer frontend-design y modern-web-guidance, y elegir con qué
# se ejecuta el CLI de skills): mismos criterios que scripts/integrations.sh. Hechos, no decisiones.
IW=""
if [ -f package.json ] && grep -Eq '"(react|react-dom|vue|svelte|@angular/core|next|nuxt|solid-js|preact|astro|lit|@remix-run/react|@sveltejs/kit|electron|@tauri-apps/api)"[[:space:]]*:' package.json; then IW="si (package.json)"
elif [ -d src-tauri ]; then IW="si (src-tauri)"
else
  H1=$(find . -maxdepth 5 \( $PRUNE -o -name .sfp -o -name .archify -o -name coverage -o -name htmlcov -o -name site -o -name _build \) -prune -o -type f \( -name '*.tsx' -o -name '*.jsx' -o -name '*.vue' -o -name '*.svelte' -o -name '*.html' -o -name '*.css' -o -name '*.scss' \) -print 2>/dev/null | head -1)
  [ -n "$H1" ] && IW="si (${H1#./})"
fi
echo "interfaz_web: ${IW:-no detectada}"
PMG=""
[ -f package.json ] && PMG=$(sed -n 's/.*"packageManager"[[:space:]]*:[[:space:]]*"\([a-z]*\)@.*/\1/p' package.json | head -1)
if [ -z "$PMG" ]; then
  if [ -f pnpm-lock.yaml ]; then PMG=pnpm
  elif [ -f bun.lock ] || [ -f bun.lockb ]; then PMG=bun
  elif [ -f yarn.lock ]; then PMG=yarn
  elif [ -f package-lock.json ]; then PMG=npm; fi
fi
echo "gestor_de_paquetes_js: ${PMG:-no declarado}"

section "monorepo"
MONO=no
for f in pnpm-workspace.yaml lerna.json nx.json turbo.json go.work rush.json; do [ -f "$f" ] && { echo "indicador: $f"; MONO=posible; }; done
[ -f package.json ] && grep -q '"workspaces"' package.json 2>/dev/null && { echo "indicador: package.json workspaces"; MONO=posible; }
[ -f Cargo.toml ] && grep -q '^\[workspace\]' Cargo.toml 2>/dev/null && { echo "indicador: Cargo workspace"; MONO=posible; }
NMAN=$(files_d 3 | awk -F/ '$NF=="package.json"||$NF=="go.mod"||$NF=="pyproject.toml"||$NF=="Cargo.toml"||$NF=="pom.xml"' | wc -l | tr -d ' ')
echo "manifiestos_en_prof<=3: $NMAN"
[ "$NMAN" -gt 2 ] && MONO=posible
echo "monorepo: $MONO"

section "calidad-y-tests"
echo "linters/formatters/tipos (configs en raiz):"
for p in .eslintrc .eslintrc.js .eslintrc.cjs .eslintrc.json .eslintrc.yml eslint.config.js eslint.config.mjs eslint.config.ts .prettierrc .prettierrc.json .prettierrc.yml prettier.config.js .editorconfig biome.json biome.jsonc tsconfig.json jsconfig.json .flake8 ruff.toml .ruff.toml mypy.ini pyrightconfig.json tox.ini setup.cfg .rubocop.yml .golangci.yml .golangci.yaml rustfmt.toml clippy.toml .stylelintrc .stylelintrc.json phpstan.neon phpcs.xml checkstyle.xml; do
  [ -e "$p" ] && echo "  $p"
done
echo "directorios_de_tests (prof<=3):"
find . -maxdepth 3 \( $PRUNE \) -prune -o -type d \( -name test -o -name tests -o -name __tests__ -o -name spec -o -name e2e -o -name cypress -o -name playwright \) -print 2>/dev/null | sed 's#^\./##' | sort | head -15 | sed 's/^/  /'
# Tests fuera de las carpetas de tests (junto al código): hecho para references/development-practices.md sección 5.
TJ=$(find . -maxdepth 6 \( $PRUNE -o -name test -o -name tests -o -name __tests__ -o -name spec -o -name e2e -o -name cypress -o -name playwright \) -prune -o -type f \( -name '*.test.*' -o -name '*.spec.*' -o -name '*_test.go' -o -name '*_test.py' -o -name 'test_*.py' -o -name '*Test.java' -o -name '*Test.kt' -o -name '*Tests.cs' -o -name '*_spec.rb' \) -print 2>/dev/null | sed 's#^\./##' | LC_ALL=C sort)
NTJ=0
[ -n "$TJ" ] && NTJ=$(printf '%s\n' "$TJ" | grep -c .)
echo "tests_fuera_de_carpetas_de_tests: $NTJ"
[ "$NTJ" -gt 0 ] && printf '%s\n' "$TJ" | head -10 | sed 's/^/  /'
echo "configs_de_test:"
for p in jest.config.js jest.config.ts jest.config.cjs jest.config.mjs vitest.config.ts vitest.config.js playwright.config.ts playwright.config.js cypress.config.ts cypress.config.js pytest.ini conftest.py phpunit.xml .mocharc.json karma.conf.js; do
  [ -e "$p" ] && echo "  $p"
done

section "ci-cd"
for d in .github/workflows .gitlab-ci.yml .circleci azure-pipelines.yml Jenkinsfile .travis.yml bitbucket-pipelines.yml .drone.yml .buildkite cloudbuild.yaml .woodpecker; do
  [ -e "$d" ] && { echo "  presente: $d"; [ -d "$d" ] && ls "$d" 2>/dev/null | head -15 | sed 's/^/    /'; }
done
exists_any .github/CODEOWNERS CODEOWNERS .github/pull_request_template.md .github/PULL_REQUEST_TEMPLATE.md .github/dependabot.yml renovate.json
echo "(no se evalúan reglas de CI: revisar a mano si valida estructura/archivos nuevos)"

section "documentacion-existente"
for p in README.md README README.rst CONTRIBUTING.md CHANGELOG.md CODE_OF_CONDUCT.md SECURITY.md LICENSE docs doc documentation wiki; do
  [ -e "$p" ] && echo "  $p"
done
echo "contratos_de_api (OpenAPI/Swagger, prof<=4):"
find . -maxdepth 4 \( $PRUNE \) -prune -o -type f \( -iname 'openapi.json' -o -iname 'openapi.yaml' -o -iname 'openapi.yml' -o -iname 'swagger.json' -o -iname 'swagger.yaml' -o -iname 'swagger.yml' -o -iname '*.openapi.json' -o -iname '*.openapi.yaml' -o -iname '*.openapi.yml' \) -print 2>/dev/null | sed 's#^\./##' | LC_ALL=C sort | head -10 | sed 's/^/  /'
echo "candidatos_adr_runbooks_lessons (prof<=4):"
find . -maxdepth 4 \( $PRUNE \) -prune -o -type d \( -iname adr -o -iname adrs -o -iname decisions -o -iname 'architecture-decision*' -o -iname rfc -o -iname rfcs -o -iname runbook -o -iname runbooks -o -iname playbooks -o -iname lessons -o -iname lessons-learned -o -iname postmortems \) -print 2>/dev/null | sed 's#^\./##' | sort | head -20 | sed 's/^/  /'

section "specs (convenciones conocidas, NO exhaustivo; la herramienta se confirma con references/tooling.md sección 1)"
NSPEC=0
for d in openspec .specify specs spec rfcs rfc docs/specs docs/rfcs; do
  [ -d "$d" ] || continue
  NSPEC=$((NSPEC + 1))
  echo "  presente: $d ($(count_subdirs "$d") subcarpetas)"
  if [ -d "$d/changes" ]; then
    echo "    changes_en_curso: $(find "$d/changes" -mindepth 1 -maxdepth 1 -type d ! -name archive ! -name archived 2>/dev/null | wc -l | tr -d ' ')"
    for a in archive archived; do
      [ -d "$d/changes/$a" ] && echo "    changes_archivados: $(count_subdirs "$d/changes/$a")"
    done
  fi
done
[ "$NSPEC" -eq 0 ] && echo "  ninguna carpeta de specs conocida (puede existir con otro nombre: revisar documentacion-existente)"

section "estructura-de-codigo (señales para references/project-structure.md sección 3; hechos, no decisiones)"
# 1) carpetas de feature/módulo y cuántas subcarpetas tiene cada una
FEAT_DIRS=$(find . -maxdepth 4 \( $PRUNE \) -prune -o -type d \( -iname features -o -iname modules -o -iname modulos -o -iname 'módulos' -o -iname funcionalidades \) -print 2>/dev/null | sed 's#^\./##' | sort)
echo "carpetas_feature_o_modulo (features/, modules/, modulos/, funcionalidades/; prof<=4):"
if [ -z "$FEAT_DIRS" ]; then
  echo "  ninguna"
  FEAT_MAX=0
else
  echo "$FEAT_DIRS" | while IFS= read -r d; do echo "  $d: $(count_subdirs "$d")"; done
  FEAT_MAX=$(echo "$FEAT_DIRS" | while IFS= read -r d; do count_subdirs "$d"; done | sort -n | tail -1)
fi
echo "features_max: ${FEAT_MAX:-0}"
# 2) primer nivel de cada raíz de código: ¿por capas técnicas o por feature?
echo "raices_de_codigo (src/ prof<=3, app/ y lib/ en raíz, carpetas con *.csproj prof<=3):"
ROOTS=$( { find . -maxdepth 3 \( $PRUNE \) -prune -o -type d -name src -print 2>/dev/null; for r in app lib; do [ -d "$r" ] && echo "./$r"; done; find . -maxdepth 3 \( $PRUNE \) -prune -o -type f -name '*.csproj' -print 2>/dev/null | sed 's#/[^/]*$##'; } | sed 's#^\./##' | grep -v '^\.$' | sort -u)
if [ -z "$ROOTS" ]; then
  echo "  ninguna"
else
  echo "$ROOTS" | while IFS= read -r r; do
    R2=$(raiz_efectiva "$r")
    SUBS=$(find "$R2" -mindepth 1 -maxdepth 1 -type d ! -name '.*' 2>/dev/null | sed 's#.*/##' | sort)
    N=$(printf '%s' "$SUBS" | grep -c . 2>/dev/null); N=${N:-0}
    LAY=$(printf '%s\n' "$SUBS" | grep -iE "$LAYER_RE" | tr '\n' ' ')
    M=$(printf '%s\n' "$SUBS" | grep -ciE "$LAYER_RE" 2>/dev/null); M=${M:-0}
    if [ "$M" -ge 2 ] && [ $((M * 2)) -ge "$N" ]; then C=por-capas
    elif [ "$M" -ge 2 ]; then C=mixto
    elif printf '%s\n' "$SUBS" | grep -qiE "$FEAT_RE"; then C=por-feature
    else C=indeterminado; fi
    [ "$R2" != "$r" ] && EF=" (raíz efectiva: $R2)" || EF=""
    echo "  $r:$EF carpetas=$N capas=$M ${LAY:+(${LAY% }) }clasificacion=$C"
  done
fi
# 3) convención impuesta por framework (manda sobre el perfil)
echo "convencion_de_framework (prof<=3):"
FW=$(files_d 3 | sed 's#^\./##' | awk -F/ '
  $NF ~ /^next\.config\.(js|mjs|cjs|ts)$/ {print "  next: "$0; next}
  $NF ~ /^nuxt\.config\.(js|mjs|ts)$/ {print "  nuxt: "$0; next}
  $NF ~ /^remix\.config\.(js|mjs|cjs|ts)$/ {print "  remix: "$0; next}
  $NF ~ /^svelte\.config\.(js|mjs|cjs|ts)$/ {print "  svelte/sveltekit: "$0; next}
  $NF ~ /^astro\.config\.(js|mjs|cjs|ts)$/ {print "  astro: "$0; next}
  $NF == "angular.json" {print "  angular: "$0; next}
  $NF == "nest-cli.json" {print "  nestjs: "$0; next}
  $NF == "metro.config.js" {print "  react-native: "$0; next}
  $NF == "manage.py" {print "  django: "$0; next}
  $NF == "artisan" {print "  laravel: "$0; next}
  $NF == "pubspec.yaml" {print "  flutter/dart: "$0; next}
  $NF ~ /^settings\.gradle(\.kts)?$/ {print "  gradle (módulos): "$0; next}
  $0 ~ /(^|\/)config\/routes\.rb$/ {print "  rails: "$0; next}')
XC=$(find . -maxdepth 3 \( $PRUNE \) -prune -o -type d -name '*.xcodeproj' -print 2>/dev/null | sed 's#^\./##' | head -5 | sed 's/^/  xcode: /')
if [ -z "$FW$XC" ]; then echo "  ninguna detectada"; else printf '%s\n' "$FW" "$XC" | grep . | sort; fi
orn() { [ -n "$1" ] && echo "$1" || echo "${2:-ninguna}"; }
echo "carpetas_de_rutas_de_framework: $(orn "$(for d in app pages src/app src/pages src/routes; do [ -d "$d" ] && printf '%s ' "$d"; done)")"
# 4) desplegables: subcarpetas de apps/ y services/ con manifiesto propio, y subproyectos de primer nivel
echo "contenedores_de_workspaces:"
DEPLOY=0
for base in apps services packages libs; do
  [ -d "$base" ] || continue
  T=$(count_subdirs "$base")
  W=$(find "$base" -mindepth 1 -maxdepth 1 -type d ! -name '.*' 2>/dev/null | sort | while IFS= read -r s; do [ -n "$(manifests_in "$s")" ] && echo x; done | wc -l | tr -d ' ')
  echo "  $base/: $T subcarpetas, $W con manifiesto propio"
  find "$base" -mindepth 1 -maxdepth 1 -type d ! -name '.*' 2>/dev/null | sort | while IFS= read -r s; do
    echo "    $s: $(manifests_in "$s" | tr '\n' ' ')"
  done
  case "$base" in apps|services) DEPLOY=$((DEPLOY + W)) ;; esac
done
SUBP=$(find . -mindepth 1 -maxdepth 1 \( $PRUNE \) -prune -o -type d ! -name '.*' -print 2>/dev/null | sed 's#^\./##' | grep -vE '^(apps|services|packages|libs|docs|scripts|tests?|examples?|demo)$' | sort | while IFS= read -r s; do m=$(manifests_in "$s" | tr '\n' ' '); [ -n "$m" ] && echo "  $s: $m"; done)
echo "subproyectos_de_primer_nivel_con_manifiesto:"
if [ -n "$SUBP" ]; then echo "$SUBP"; else echo "  ninguno"; fi
NSUBP=$(printf '%s' "$SUBP" | grep -c . 2>/dev/null); NSUBP=${NSUBP:-0}
DEPLOY=$((DEPLOY + NSUBP))
[ "$DEPLOY" -eq 0 ] && [ -n "$(manifests_in .)" ] && DEPLOY=1
echo "desplegables_estimados: $DEPLOY (apps/* + services/* + subproyectos de primer nivel con manifiesto; 1 si solo hay manifiesto en raíz. Un manifiesto no prueba despliegue independiente: confirmar con el usuario)"
# 5) pistas de otros perfiles
echo "pistas:"
echo "  package_json_exports: $( [ -f package.json ] && grep -q '"exports"[[:space:]]*:' package.json 2>/dev/null && echo si || echo no)"
echo "  archivos_tf: $(files_d 6 | grep -c '\.tf$')"
echo "  notebooks_ipynb: $(files_d 6 | grep -c '\.ipynb$')"
echo "  dirs_movil: $(orn "$(for d in android ios; do [ -d "$d" ] && printf '%s ' "$d"; done)" ninguno)"
echo "  dirs_envs: $(orn "$(for d in envs environments; do [ -d "$d" ] && printf '%s ' "$d"; done)" ninguno)"

section "configuracion-agentes-ide (convenciones conocidas, NO exhaustivo)"
exists_any CLAUDE.md .claude .claude/agents .claude/skills .claude/commands .claude/settings.json AGENTS.md GEMINI.md .gemini .codex .cursor .cursorrules .cursor/rules .windsurf .windsurfrules .github/copilot-instructions.md .github/instructions .kiro .opencode opencode.json .aider.conf.yml .aiderignore .continue .zed .vscode .idea .fleet .mcp.json .clinerules .roo .roomodes .amazonq CONVENTIONS.md
echo "otros_archivos_de_instrucciones (por nombre, prof<=3):"
find . -maxdepth 3 \( $PRUNE \) -prune -o -type f \( -iname 'agents.md' -o -iname 'claude.md' -o -iname 'gemini.md' -o -iname '*instructions*.md' -o -iname '*.mdc' -o -iname 'SKILL.md' \) -print 2>/dev/null | sed 's#^\./##' | sort | head -30 | sed 's/^/  /'

section "orquestacion-existente"
echo "(el orquestador NO se detecta por convención de archivos: se pregunta al usuario, entrevista 15, y se investiga con references/orchestration.md sección B.1)"
exists_any .tmux.conf tmuxinator.yml
have tmux && echo "tmux: disponible" || echo "tmux: no disponible"
echo "(worktrees_adicionales: ver sección git)"

section "setup-previo"
if [ -f .sfp/manifest.json ]; then
  echo "manifiesto: .sfp/manifest.json (modo Actualización posible)"
  head -c 600 .sfp/manifest.json | sed 's/^/  /'; echo
else
  echo "manifiesto: no"
fi
echo "archivos_con_marcadores_sfp:"
grep_files 'sfp:start' | head -20 | sed 's/^/  /'
# instalaciones anteriores a 1.5.0 usaban los nombres ".ai-setup/", "ai-setup:start/end" y el tag "pre-ai-setup"
LEGACY=""
[ -d .ai-setup ] && LEGACY="$LEGACY .ai-setup/"
LM=$(grep_files 'ai-setup:start' | head -20)
[ -n "$LM" ] && LEGACY="$LEGACY marcadores-ai-setup"
if have git && git rev-parse --is-inside-work-tree >/dev/null 2>&1 && [ -n "$(git tag -l 'pre-ai-setup*' 2>/dev/null)" ]; then LEGACY="$LEGACY tag-pre-ai-setup"; fi
if [ -n "$LEGACY" ]; then
  echo "instalacion_con_nombres_antiguos:$LEGACY (anterior a 1.5.0: modo Actualización, migrar a .sfp/ y sfp:start/end; CHANGELOG 1.5.0)"
  [ -n "$LM" ] && printf '%s\n' "$LM" | sed 's/^/  marcadores antiguos: /'
fi

section "metodologia-global"
FOUND=0
# ~/sfp es solo el nombre de ejemplo; ~/ai se sigue buscando por compatibilidad con carpetas ya creadas
for c in "$GLOBAL_HINT" "${SFP_METHODOLOGY_DIR:-}" "$HOME/sfp" "$HOME/.sfp" "$HOME/ai" "$HOME/.ai"; do
  [ -n "$c" ] && [ -d "$c" ] && { echo "carpeta: $c"; ls "$c" 2>/dev/null | head -15 | sed 's/^/  /'; FOUND=1; }
done
[ "$FOUND" -eq 0 ] && echo "carpeta: no encontrada en ubicaciones estándar (preguntar al usuario)"

section "riesgos-secretos (SOLO rutas, nunca contenido)"
echo "archivos_sensibles_por_nombre:"
find . \( $PRUNE \) -prune -o -type f \( -name '.env' -o -name '.env.*' -o -name '*.pem' -o -name '*.key' -o -name '*.p12' -o -name '*.pfx' -o -name 'id_rsa*' -o -name 'id_ed25519*' -o -name 'credentials*' -o -name 'secrets*' -o -name '*.keystore' -o -name '.npmrc' -o -name '.pypirc' -o -name 'service-account*.json' \) -print 2>/dev/null | sed 's#^\./##' | grep -v -e '\.example$' -e '\.sample$' -e '\.template$' | sort | head -20 | sed 's/^/  /'
echo "archivos_con_patrones_de_credenciales (solo ruta):"
grep_files -E 'AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|ghp_[A-Za-z0-9]{36}|xox[baprs]-[A-Za-z0-9-]{10,}|sk-[A-Za-z0-9]{20,}' | head -20 | sed 's/^/  /'
if have git && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "env_trackeado_en_git:"
  git ls-files 2>/dev/null | grep -E '(^|/)\.env($|\.)' | grep -v -e example -e sample -e template | head -10 | sed 's/^/  /'
  [ -f .gitignore ] && { grep -qE '^\.env' .gitignore && echo "gitignore_cubre_env: si" || echo "gitignore_cubre_env: no"; } || echo "gitignore: no existe"
fi

section "fin"
echo "discovery_completo: si (solo lectura; nada fue modificado)"
echo "recordatorio: lo no listado no implica ausencia; las listas de convenciones son orientativas"
