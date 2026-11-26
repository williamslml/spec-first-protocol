# Arquitectura de carpetas recomendada y qué crear en cada caso

Fuente: texto completo en `sfp-con-orquestador.md` sección 21 y `sfp-sin-orquestador.md` sección 20 (estructura global, ubicaciones y carga, contenido de cada documento); resumen en `methodology-digest.md`. Los nombres son **recomendación**, no obligación: si el proyecto ya tiene equivalentes, se reutilizan (ver `scenarios.md`). Crear solo lo que el usuario aceptó y justificó (contexto mínimo, no sobrediseñar).

## 1. Carpeta de metodología global (fuera de los proyectos)

`~/sfp/` es solo un **nombre de ejemplo**: el usuario elige nombre y ubicación.

```
<carpeta de metodología global>/   (ejemplo: ~/sfp/)
├── SYSTEM.md                       # propósito, principios, arquitectura, capas, reglas fundamentales (NO todas las reglas operativas)
├── methodology/
│   ├── DEVELOPMENT.md
│   ├── ARCHITECTURE.md
│   ├── TESTING.md
│   ├── SECURITY.md
│   ├── DEVOPS.md
│   ├── QUALITY.md
│   └── DOCUMENTATION.md
├── skills/                         # fuente de verdad de skills: una carpeta por skill que el usuario adoptó (sección 6)
├── tools/                          # una carpeta por tool que el usuario adoptó (sección 6)
└── agents/
    ├── architect.md
    ├── developer.md
    ├── frontend.md
    ├── tester.md
    └── reviewer.md
```

Reglas:
- Es la **fuente de verdad**, independiente del runtime (herramienta de IA): ninguno la lee solo; cada uno necesita una capa de enlace (enlace simbólico, copia generada o referencia por ruta; ver `runtime-adapters.md`).
- **Qué crear (no todo "por si acaso"):**
  - `SYSTEM.md`: siempre que se cree la carpeta global.
  - `methodology/*.md`: solo los que pida el usuario; empezar con esqueleto (sección 5) y completar con experiencia. No inventar estándares.
  - `agents/*.md`: solo los roles elegidos.
  - `skills/`, `tools/`: solo lo que el usuario ya usa o decide adoptar; nunca instalar sin aprobación (sección 6).
  - `evals/`: **no crear**; es infraestructura futura.
  - **No** crear `PERFORMANCE.md` (va en `QUALITY.md`) ni un `FOLDER_STRUCTURE.md` **global**: la estructura de carpetas del código se decide **por proyecto** (perfiles por tipo de proyecto y etapa en `references/project-structure.md`).
- La estructura puede evolucionar; no volverla antes de tiempo una clasificación excesiva.
- **Versionada con Git**: proponer `git init` en la carpeta global y un commit (cambio guardado) por cambio aprobado, para rastrear qué cambió, por qué, cuándo, qué experiencia lo originó y qué impacto tuvo. Sus cambios pasan por el proceso formal de promoción (nunca automáticos).

## 2. Estructura dentro de cada proyecto

```
<proyecto>/
├── <ruta de specs>/                # capa de especificación (si el usuario la usa); la ruta la fija su herramienta (tooling.md sección 1)
│   ├── <specs vigentes>/
│   └── <changes>/
│       ├── <en-curso>/             # propuesta, requisitos, diseño, tareas
│       └── <archivados>/           # changes cerrados
└── docs/
    ├── adr/                        # decisiones arquitectónicas permanentes (0001-xxx.md)
    ├── runbooks/                   # procedimientos operativos repetibles
    └── lessons/                    # lecciones aprendidas, formato "Aplica cuando: …"
```

Reglas:
- La carpeta de specs (especificaciones) vive **dentro de cada repo**, nunca en la carpeta global: es planificación del proyecto, no metodología global.
- Cada cambio de la capa de specs produce cuatro documentos por función: propuesta (por qué y qué cambia), requisitos (con escenarios comprobables), diseño (enfoque técnico) y tareas (checklist, unidad de trabajo). Nombres y rutas son los de la herramienta elegida por el usuario (correspondencia en `manifest.json.spec_layer`, ver `tooling.md` sección 1); aquí se usan `proposal.md`/`specs/`/`design.md`/`tasks.md` solo como nombres genéricos. Sin herramienta, el usuario elige los nombres y se registran igual.
- ADRs (decisiones de arquitectura): `docs/adr/NNNN-titulo.md`, con Status, Context, Decision, Alternatives, Consequences, References.
- Runbooks (guías de operación): despliegue, vuelta atrás, recuperación, migraciones, resolución de problemas, respuesta a incidentes, mantenimiento.
- `docs/lessons/`: con orquestador (coordina agentes), alimenta y complementa su memoria; sin él, es el registro manual principal.
- Carpetas vacías no aportan: crearlas con un README breve o `.gitkeep` solo si el usuario quiere ver la estructura; si no, al primer uso.
- Memoria a largo plazo (sección 10 de `development-practices.md`): cada ADR y cada lección llevan su estado, y `docs/adr/README.md` y `docs/lessons/README.md` son índices de lo vigente, con lo reemplazado o superado aparte. Nada se borra por antigüedad.

## 3. Qué crear según el caso

| Caso / combinación | Global | Dentro del repo |
|---|---|---|
| 2. Nuevo | Referenciar o crear (con permiso) | Árbol completo aceptado en la entrevista (specs, adr, runbooks, lessons) + instrucciones por runtime |
| 1. Existente · Integrar | Igual | Solo lo que falte; reutilizar equivalentes (p. ej. `docs/decisions/` ≈ `docs/adr/`) y documentar el mapeo en las instrucciones |
| 3. Existente · Reestructurar | Igual | Mover o renombrar hacia el árbol de la sección 2 según el mapa antes→después aprobado (con respaldo obligatorio) |
| 4. Existente · Solo metodología | Igual | **Nada nuevo en carpetas**: instrucciones fuera del repo, un único archivo en la raíz, o archivos en ubicaciones existentes. Specs, ADRs y lecciones: donde el proyecto ya los guarde, o fuera del repo |
| 5. Sin orquestador | Variante sin orquestador | Specs como estado compartido; `docs/lessons/` manual; métricas manuales; guía de worktree (copia de trabajo) o rama por sesión paralela |
| 6. Con orquestador | Variante con orquestador | Configuración del orquestador (ubicación según su documentación vigente); `docs/lessons/` sigue siendo la fuente de verdad del proyecto |

## 4. Global vs proyecto: qué va dónde

| Contenido | Dónde |
|---|---|
| Principios, metodología, plantillas de agentes, skills reutilizables | Global |
| Arquitectura, APIs, decisiones, integraciones, convenciones, infraestructura, resolución de problemas de un proyecto | Proyecto (no pasa solo a otros) |
| Planificación por funcionalidad (specs) | Proyecto |
| Memoria operativa de un orquestador | Su propia ubicación (puede estar fuera del repo); no es fuente de verdad |
| Lecciones del proyecto | `docs/lessons/` del proyecto; solo pasan a global por el flujo de promoción |

Autoridad: el proyecto puede apartarse a propósito de un valor global por defecto; toda desviación arquitectónica relevante va en un ADR. Las restricciones críticas de seguridad siguen vigentes salvo decisión humana explícita.

## 5. Esqueleto de los documentos de `methodology/` (qué cubre cada uno)

Solo esqueletos de cobertura; el contenido real depende del proyecto o usuario y se redacta con experiencia comprobada. No inventar reglas.

| Archivo | Cubre |
|---|---|
| `SYSTEM.md` | Propósito, principios, arquitectura, responsabilidades, relación entre capas, reglas fundamentales |
| `DEVELOPMENT.md` | Git, ramas, commits, modularidad, dependencias, nombres, convenciones, PRs (solicitudes de cambio), colaboración, mantenimiento |
| `ARCHITECTURE.md` | Principios, componentes, límites, acoplamiento y cohesión, interfaces, patrones, decisiones, pros y contras (no impone la misma arquitectura a todos) |
| `TESTING.md` | Pruebas unitarias, de integración, de extremo a extremo y de contrato; simulaciones, datos de prueba, regresión, cobertura, casos límite (la estrategia depende del proyecto) |
| `SECURITY.md` | Secretos, autenticación y autorización, validación, saneamiento, OWASP, dependencias, registros, mínimo privilegio, seguridad de APIs, errores seguros |
| `DEVOPS.md` | Docker, CI/CD (automatización), entornos, despliegue, migraciones, reversión, secretos, observabilidad, respaldos, recuperación ante desastres |
| `QUALITY.md` | Corrección, mantenibilidad, legibilidad, tipado seguro, lint (revisión automática), formato, complejidad, manejo de errores, rendimiento básico, definición de terminado |
| `DOCUMENTATION.md` | README, docs de APIs, ADRs, runbooks, changelog (registro de cambios), documentación técnica y de despliegue |

## 6. Skills y herramientas: catálogo por función

Estructura de cada skill (paquete de instrucciones; detalle bajo demanda): `SKILL.md` + `references/` + `examples/` + `scripts/`. Distinguir **skill** (capacidad especializada) de **tool** (instrumento operativo).

| Función | Capacidad | Candidata conocida | Cuándo plantearla en el setup |
|---|---|---|---|
| Flujo de trabajo (solo lo que SFP no cubre) | TDD (test primero), depuración sistemática, verificar antes de dar por terminado, recibir hallazgos de revisión, cierre de rama | **Superpowers**, solo el subconjunto de la sección 6.1 | Preguntar si ya usa alguno. SFP ya cubre especificación, planificación, tareas, sub-agentes, worktrees y revisión crítica (reglas 8 y 9 del resumen, `methodology-digest.md`, y `orchestration.md`): esas partes de Superpowers **no se instalan** |
| Navegación semántica de código | Buscar símbolos y referencias, refactorizar por símbolo (LSP) | **Serena** | Solo si el discovery (análisis inicial) muestra un repo grande: `archivos` ≥ 1000 en `tamano-y-estructura`, o `monorepo: si` (umbral por defecto de la skill; el usuario puede fijar otro) |
| Menos ruido en la terminal | Menos tokens (unidades de texto) por salida de comando (optimización, no metodología) | **RTK** | Opcional. Su hook (script automático) vive en la configuración **global** del runtime: cambio de configuración global (regla inviolable 7, confirmación aparte) |
| Visualización de arquitectura | Diagramas de componentes, flujos, secuencia y datos; complementa `ARCHITECTURE.md` | **archify** | Opcional |
| Diseño visual de frontend | Dirección visual, tipografía, coherencia; no cargarla en backend | **frontend-design** | Solo si hay frontend |

Reglas:
- La columna "Candidata conocida" son **opciones que la skill puede ofrecer por nombre**, no una lista cerrada ni una dependencia: el usuario puede preferir otra, otra función o ninguna.
- Los textos de SFP (`sfp-*-orquestador.md`) son neutrales; este catálogo es de la skill instaladora, no de la metodología. Para orquestadores y herramientas de specs, la skill sigue sin nombrar productos (`orchestration.md` sección B.1, `tooling.md` sección 1).
- Antes de planificar una candidata, o una herramienta que nombre el usuario, se averiguan sus capacidades, límites e instalación con `tooling.md` sección 2 (fuente oficial y método de instalación **vigentes**, no de memoria).
- No instalar nada sin aprobación. Ofrecerlas según el tipo de proyecto detectado, nunca por defecto. Cada skill, agente o herramienta debe justificar su existencia.
- Las candidatas se instalan con `scripts/integrations.sh` (sección 6.2), nunca con comandos sueltos.

### 6.1 Matriz de responsabilidades y enrutamiento (sfp + candidatas)

Fuente única de verdad del enrutamiento. Si dos filas parecen aplicar, **gana la de SFP**. Una candidata no instalada no se enruta; su fila se omite al copiar la matriz al proyecto (`templates.md` sección 3).

**Lo que decide SFP (ninguna candidata actúa aquí):**

| Disparador | Responsable | Prohibido explícitamente |
|---|---|---|
| Idea vaga, requisitos, propuesta, "explorar" | Capa de specs de SFP (propose) y entrevista | Brainstorming de Superpowers (no se instala). archify no propone soluciones |
| Plan, diseño y tareas de un cambio no trivial | Capa de specs de SFP (design → `tasks.md`) | `writing-plans` y `executing-plans` (no se instalan). Ninguna candidata crea ni reescribe specs o tareas |
| Repartir trabajo entre agentes o sub-agentes, paralelizar | Roles y orquestación de SFP (`orchestration.md`) | `subagent-driven-development` y `dispatching-parallel-agents` (no se instalan) |
| Aislamiento por sesión: ramas y worktrees | SFP (`orchestration.md` secciones A y B) | `using-git-worktrees` (no se instala) |
| Pedir una revisión crítica | Rol Reviewer de SFP (`templates.md` sección 7, otra sesión u otro modelo; regla 8 del resumen) | `requesting-code-review` (no se instala) |
| Orden y contenido de los controles de calidad (gates) | SFP (`templates.md` sección 14; sección 6 del digest) | Ninguna candidata añade, salta ni reordena gates |
| Memoria del proyecto: ADR, lecciones, runbooks | SFP (`docs/adr/`, `docs/lessons/`, `docs/runbooks/`) | Memorias y onboarding de Serena (se arranca con `--add-mode no-memories`) |
| Instalar, actualizar o retirar la metodología | `spec-first-protocol` | Ninguna candidata modifica `.sfp/` ni los bloques `sfp:start`/`sfp:end` |

**Lo que complementa cada candidata:**

| Disparador | Herramienta | Prohibido explícitamente |
|---|---|---|
| Implementar un ítem de `tasks.md` (o un cambio trivial) con comportamiento comprobable | `test-driven-development` (Superpowers) | Saltarse la spec en cambios no triviales. Los tests escritos primero viven **dentro** del paso de implementación: el gate de tests sigue después y ejecuta la suite completa (el orden de gates no cambia) |
| Un bug, un test que falla, un comportamiento inesperado | `systematic-debugging` (Superpowers) | Aplicar un arreglo que cambie contratos o comportamiento sin pasar por la spec (regla 3 del resumen) |
| A punto de dar por terminado, hacer commit o abrir una PR | `verification-before-completion` (Superpowers) | Inventar comandos de verificación: usar los de "Verificación" del punto de entrada (`templates.md` sección 3) |
| Llegan hallazgos del Reviewer de SFP o de una persona | `receiving-code-review` (Superpowers) | Iniciar revisiones (eso es SFP) |
| Trabajo terminado y verificado: decidir merge, PR, conservar o descartar | `finishing-a-development-branch` (Superpowers) | Hacer merge, push o borrar ramas sin aprobación humana (acción de alto impacto); crear worktrees |
| Encontrar símbolos o referencias, renombrar o refactorizar por símbolo, en un repo grande | Serena (contexto `claude-code`) | Leer, listar o buscar texto: eso es de las herramientas propias del runtime (el contexto `claude-code` ya excluye `read_file`, `list_dir`, `find_file`, `search_for_pattern`, `create_text_file` y `execute_shell_command`). Memorias, onboarding, documentación |
| Diagramar lo **ya decidido o existente**: discovery, `ARCHITECTURE.md`, ADR, documentación | archify | Proponer o decidir arquitectura (eso es la fase de diseño de la spec). Explicaciones no pedidas (no añadir líneas `[archify explainer: …]`). Sus archivos van a `.archify/` o a la ruta de docs que indique el usuario, nunca dentro de las specs |
| Salida de comandos rutinarios (git, tests, listados) | RTK (hook automático) | Comprimir evidencia de SFP: los scripts de `spec-first-protocol` están excluidos en su configuración, y los comandos de evidencia (Fase 1, final de la Fase 6, Fase 7 y Retiro) van con `RTK_DISABLED=1`. Si una salida comprimida no basta, repetir con `rtk bypass <cmd>` (`rtk proxy` es su alias obsoleto). Nunca adoptar su proxy de API (`ANTHROPIC_BASE_URL`) |
| Crear o rediseñar la interfaz: componentes, páginas, estilos | frontend-design | Backend, APIs, datos, arquitectura general y elección de tecnologías. No sustituye los gates (la accesibilidad se comprueba con tests o lint) |

**Partes de Superpowers excluidas y por qué:** `brainstorming`, `writing-plans`, `executing-plans` (capa de specs de SFP); `subagent-driven-development`, `dispatching-parallel-agents` (roles y orquestación); `using-git-worktrees` (aislamiento de SFP); `requesting-code-review` (Reviewer de SFP); `using-superpowers` y el hook `SessionStart` del plugin (obligan a cargar skills antes de cualquier respuesta y pisarían las reglas de SFP); `diagnosing-superpowers` (solo sirve para el plugin completo); `writing-skills` (fuera del alcance de SFP). Por eso Superpowers **nunca se instala como plugin**: solo las 5 skills de la tabla, como skills sueltas. Algunas citan otras con prefijo (`superpowers:test-driven-development`, `superpowers:writing-skills`…): si la citada está instalada, se usa por su nombre sin prefijo; si es una excluida, se ignora la referencia y manda la fila de SFP correspondiente.

### 6.2 Instalación: `scripts/integrations.sh`

Instala, comprueba y retira las candidatas aprobadas. **Solo para Claude Code** (`.claude/skills`, `.mcp.json`, `~/.claude/settings.json`); en otros runtimes, cada candidata pasa por `tooling.md` sección 2 y una instalación manual aprobada. Requiere **Bash ≥ 4** (no `sh`/dash): `bash scripts/integrations.sh --help` (Windows: `run.ps1 integrations …`, que usa el `bash` de Git Bash o de WSL).

- **Modos.** Sin opciones, **plan** (no escribe). `--apply` instala, registra lo hecho y ejecuta el chequeo de las 6 piezas. `--check` solo hace el chequeo. `--uninstall` muestra el plan de retiro y `--uninstall --apply` lo ejecuta.
- **Versiones fijadas** en la cabecera del script: CLI de skills, archify, frontend-design (commit), Superpowers, `serena-agent`, Python de Serena, rtk y uv (winget con `--version`; instaladores `curl | sh` en la URL de esa versión). Para cambiarlas: editar la cabecera, revisar la fuente de esa versión y repetir el chequeo.
- **Global frente a proyecto.** Lo que ya existe globalmente se usa sin duplicarlo (`[GLOBAL DETECTADO]`). Lo que falta va al proyecto por defecto (`--scope project`): skills en `<proyecto>/.claude/skills/` y Serena en `<proyecto>/.mcp.json` vía `uvx` con versión fijada (portable para el equipo). `--scope global` lo instala en `~/.claude/skills/` y como MCP (conector de herramientas) de usuario. Son skills de terceros para el runtime: **no** van a la carpeta de metodología global (sección 1, `skills/` propias del usuario), que Claude Code no lee.
- **Siempre globales por naturaleza** (marcadas `(global)` o "retiro [MANUAL]" en la salida): los binarios `rtk` y `uv`, el hook de RTK en `~/.claude/settings.json` (más `~/.claude/RTK.md`) y las exclusiones de los scripts de SFP en el `config.toml` de RTK. Cambiar configuración global lleva confirmación aparte (regla inviolable 7).
- **Estado y retiro.** Con `--apply` guarda en `<proyecto>/.sfp/integrations.json` la selección (`--only/--skip/--scope/--rtk-scope/--force-frontend`) y un registro de cada cosa que **instaló él** (lo preexistente no se registra ni se retira); con `--state <ruta>` va fuera del repo (modo sin rastros). `--check` y `--uninstall` sin opciones reutilizan esa selección. El retiro deshace solo lo del proyecto (skills con el CLI oficial, la entrada `serena` de `.mcp.json` si no cambió, el bloque RTK de `CLAUDE.md`; borra `skills-lock.json` y carpetas si quedan vacíos) e imprime lo global como `[MANUAL]` con su comando exacto.
- **Relación con el manifiesto de SFP.** Las integraciones **no** se registran en `.sfp/manifest.json` (su esquema solo admite acciones de SFP dentro del proyecto): su registro es `.sfp/integrations.json`. En la Fase 7, los archivos que `verify.sh` sección 4 lista fuera del plan y que figuran en ese estado (`.claude/skills/*`, `skills-lock.json`, `.mcp.json`, `.sfp/integrations.json`) son de las integraciones, no un cambio fuera del plan. En el Retiro, `integrations.sh --uninstall` va **antes** que `uninstall.sh` (`uninstall.md` sección 2).
- **Formato.** Las fusiones conservan los datos y la sangría de `.mcp.json`. La lista `exclude_commands` de RTK se reescribe en una línea (se pierden sus comentarios internos; el resto del archivo queda igual).

## 7. Roles de agente: se definen con el usuario

Los cinco roles base (Architect, Developer, Frontend, Tester, Reviewer) son **plantillas iniciales, no una lista cerrada**. Los roles finales los define el usuario **conversando con el setup** (instalador): la skill recomienda, el usuario decide. Nunca crear un rol sin su aprobación, ni asignar tier (nivel de modelo), permisos o modelo sin que lo confirme.

### Procedimiento (Fase 2, bloque 5, y revisión en Fase 4)
1. **Partir de hechos**, no de la lista por defecto: salida de `discover.sh` (tipo de proyecto, tecnologías, tamaño, monorepo, frontend sí/no, tests/CI), equipo (solo/varios), runtimes elegidos, variante (con o sin orquestador) y criticidad.
2. **Preguntar** cómo trabaja hoy: ¿qué tareas se repiten?, ¿dónde se pierde tiempo o hay errores?, ¿qué quiere separar (p. ej. quien implementa de quien revisa)?, ¿cuántos agentes o sesiones usa a la vez?
3. **Recomendar** un conjunto mínimo, justificando cada rol, y mostrar la alternativa más simple (tabla de criterios). Cada una dice por qué, qué problema resuelve y qué costo de mantenimiento añade.
4. **Dejar editar al usuario**: aceptar, quitar, renombrar, fusionar o crear roles propios (p. ej. `security-auditor`, `data-engineer`, `docs-writer`, `devops`, `migrator`). Los nombres son suyos.
5. **Definir cada rol aprobado** completando la plantilla (`templates.md` sección 4): responsabilidad, objetivos, entradas, salidas, límites, criterios de calidad, condiciones de escalamiento (cuándo derivar). Preguntar lo no deducible; marcar `PENDIENTE:` lo que el usuario aún no sepa.
6. **Para cada rol, proponer y confirmar** por separado: tier de modelo por defecto (y modelo real del usuario), permisos mínimos de herramientas (mínimo privilegio) y qué acciones le exigen aprobación humana.
7. **Mostrar el resultado** en tabla y pedir confirmación antes de generar archivos:

| Rol | Responsabilidad (1 línea) | Tier propuesto | Permisos mínimos | Aprobación humana para | Justificación |
|---|---|---|---|---|---|

8. **Sin orquestador:** recordar que los roles se aplican por sesión (cada sesión adopta un rol); la revisión debe poder hacerse en otra sesión con otro modelo o runtime. **Con orquestador:** definir además el supervisor y los workers (ejecutores), según lo que admita su orquestador.
9. **Revisable después:** los roles evolucionan con la experiencia (métricas y lecciones). Anotar que se pueden añadir, quitar o ajustar, y que cambiar roles es un cambio de metodología con aprobación humana.

### Criterios de recomendación (propuestas del setup, no reglas de SFP)
| Situación detectada | Recomendación orientativa |
|---|---|
| Proyecto pequeño, usuario solo | Pocos roles (p. ej. developer + reviewer) o incluso uno; más roles = más mantenimiento (no sobrediseñar) |
| Cambios de riesgo medio/alto, producción, autenticación, datos o contratos de API | Separar implementación y revisión; considerar un rol de arquitectura para descomponer el trabajo y ADRs |
| Hay frontend | Rol frontend (o reglas de frontend dentro de developer si el equipo es mínimo) |
| Tests escasos o inexistentes | Rol tester, o convertir "añadir tests" en tarea explícita de developer |
| Repo grande o monorepo (varios proyectos) | Roles por área solo si las convenciones difieren; evitar duplicar instrucciones |
| Varios runtimes o modelos disponibles | Asignar el rol reviewer a otro modelo o runtime que el de implementación |
| Orquestador elegido | Un supervisor + workers mínimos; no crear workers a los que no se vaya a delegar |

La relación rol ↔ tier es una **sugerencia** (p. ej. un rol de arquitectura o de revisión final suele ir al tier de Alta capacidad, según la regla 5 del resumen); la asignación real depende de complejidad y riesgo de cada tarea, no solo del rol.

### Reglas
- No duplicar en el rol la metodología global ni todas las herramientas o skills: el rol referencia, no copia.
- Cada rol se justifica con una respuesta del usuario; si no, no se crea.
- Plantillas: `agents/*.md` en la carpeta global (fuente de verdad), proyectadas al runtime por la capa de enlace (`runtime-adapters.md`). Sin carpeta global, donde indique el usuario.

## 8. Observabilidad y métricas

Métricas iniciales: tasas de éxito, de fallos y de retrabajo, latencia y consumo de tokens o peticiones, coste, tasa de escalamiento, correcciones en revisión, tiempo de resolución, rendimiento por modelo y por tipo de tarea.
- **Con orquestador:** recolección según lo que ofrezca (comprobar en su documentación).
- **Sin orquestador:** anotación **manual** por tarea en la documentación del proyecto. Ofrecer plantilla de registro (`templates.md` sección 11).
- Nada de infraestructura compleja de entrada; primero, datos reales. `evals/` queda para el futuro.
