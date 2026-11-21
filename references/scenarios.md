# Guías por caso, discovery y casos límite

## Checklist de discovery (análisis inicial, solo lectura)

`scripts/discover.sh` revisa casi toda la lista de forma automática. La lista cubre lo que el script no ve (contenido de README e instrucciones, reglas de CI, convenciones implícitas) y sirve de respaldo manual si no se puede ejecutar.

Buscar y anotar sin modificar nada:

- **Control de versiones:** git sí/no, rama actual, cambios sin commit, remoto, ramas protegidas, hooks (scripts de git: `.git/hooks`, husky, pre-commit).
- **Stack:** lenguajes, frameworks, gestor de paquetes, lockfiles, versión de runtime.
- **Estructura:** árbol de 2–3 niveles, monorepo (varios proyectos en un repo: workspaces, turbo, nx, lerna, pnpm-workspace), carpetas generadas o de terceros.
- **Calidad:** linter, formateador, tipos, tests, cobertura, scripts de `package.json`/Makefile/equivalentes.
- **CI/CD (automatización):** pipelines, reglas que rechazan archivos nuevos o validan estructura, políticas de PR (solicitudes de cambio).
- **Documentación:** README, `docs/`, ADRs (registros de decisiones; carpetas tipo adr/decisions), runbooks (guías de operación), changelog, CONTRIBUTING.
- **Specs (especificaciones) existentes:** carpetas de alguna capa de specs (la sección `specs` de `discover.sh` lista convenciones conocidas, no todas), RFCs, tickets en el repo. Si aparece una herramienta: sección 1 de `tooling.md`.
- **Configuración de agentes:** instrucciones, reglas, agentes, skills, MCP, comandos y permisos de cualquier runtime (editor o CLI con agentes). Buscar por convención, sin suponer cuál existe. Ver `runtime-adapters.md`.
- **Convenciones propias:** nombres, commits (conventional commits), ramas, plantillas de PR.
- **Orquestación existente:** configuración de algún orquestador (coordina varios agentes) o scripts multiagente. No hay archivo fiable para detectarlo: si aparece, preguntar y resolver la sección B.1 de `orchestration.md`.
- **Riesgos:** secretos en el repo (informar existencia y ruta, nunca el contenido), archivos grandes, submódulos, enlaces simbólicos.
- **Metodología previa:** rastro de una instalación previa (`.sfp/manifest.json`, marcadores `sfp:start`).

Salida: inventario de 10–20 líneas y lista de "equivalencias" (qué de la metodología ya existe con otro nombre).

---

## sección 1 Caso 1 — Proyecto existente (Integrar)

Objetivo: añadir la metodología sin mover nada.

1. Buscar equivalencias (p. ej. `docs/decisions/` ya cumple el papel de `docs/adr/`). **Reusar lo existente**; no crear duplicados. Si el nombre difiere, anotar la equivalencia en las instrucciones en vez de renombrar.
2. Añadir solo lo que falte y el usuario aceptó: instrucciones por runtime, `docs/lessons/`, capa de specs, plantillas de los agentes elegidos.
3. Archivos existentes (README, instrucciones de runtimes): **fusionar con marcadores**, nunca reemplazar.
4. Ajustar los controles de calidad (quality gates) a los comandos reales del proyecto (leer sus scripts, no inventar).
5. Primer cambio sugerido: algo pequeño y real de los pendientes, para probar el flujo.

Riesgo típico: CI que valida estructura; comprobarlo antes (ver casos límite).

## sección 2 Caso 2 — Proyecto nuevo

Objetivo: empezar con lo mínimo útil, no con todo el catálogo.

1. Confirmar stack y tipo de proyecto; si aún no hay, no suponer uno: crear solo lo independiente del stack.
2. Estructura base (ajustada a la entrevista):
   - `docs/adr/`, `docs/runbooks/`, `docs/lessons/` (con `.gitkeep` o README breve).
   - Capa de specs, si el usuario la quiere.
   - Instrucciones de proyecto por runtime elegido.
   - Plantillas de agentes solo de los roles elegidos.
3. Si no hay git, inicializarlo (con permiso) y proponer un primer commit.
4. Controles de calidad: definirlos con textos provisionales ("pendiente: definir comando de test") hasta que existan; no fabricar comandos.
5. La estructura del código (`src/`, etc.) se propone desde `references/project-structure.md` (perfil según el tipo de proyecto, etapa según la escala), ajustada a lo que imponga el framework. Nunca se aplica sin el plan de la Fase 4 y la aprobación de la Fase 5.

## sección 3 Caso 3 — Existente + reestructurar todo

Objetivo: alinear el proyecto con la estructura de la metodología, con control total del riesgo.

Requisitos obligatorios: git limpio (sin cambios pendientes) o respaldo completo, aprobación humana explícita y análisis de dependencias de rutas.

1. **Dependencias de rutas:** imports, configuración de build, CI, scripts, Dockerfiles, documentos con enlaces, rutas en variables de entorno. Cada movimiento = lista de referencias que cambian.
2. **Mapa antes → después** por carpeta o archivo, con riesgo y si es reversible. Presentarlo y aprobarlo.
3. **Ejecutar en lotes pequeños** con movimientos que conserven el historial (`git mv`), un lote por commit (con permiso), comprobando compilación y tests tras cada uno.
4. Si un lote falla: parar, revertirlo e informar. No encadenar arreglos.
5. Dejar **notas de redirección** donde haga falta (README con el nuevo mapa) y arreglar enlaces rotos.
6. Cambiar la estructura del *código fuente* (no de documentación o metodología) solo si el usuario lo pidió expresamente; reestructurar "todo" no autoriza reescribir la arquitectura. Si se pidió, usar el perfil y los 5 pasos de migración de la sección 0 de `references/project-structure.md`, no un mapeo improvisado.
7. Rollback (vuelta atrás): tag `pre-sfp` y comandos exactos para volver.

Riesgo: alto. Si el proyecto es grande, ofrecer fases (primero documentación y metodología, luego código).

## sección 4 Caso 4 — Existente + solo metodología (sin alterar carpetas)

Objetivo: dar a los agentes las reglas de trabajo sin tocar la estructura.

Opciones, de menor a mayor presencia (elige el usuario):
1. **Fuera del repo:** configuración personal del runtime (nivel usuario) o carpeta global; el repo no cambia.
2. **Un solo archivo** de instrucciones en la raíz (o el que espere cada runtime), con marcadores; sin carpetas nuevas.
3. **Archivos en carpetas existentes** (p. ej. un `docs/` existente), sin crear carpetas.

Reglas:
- No crear `docs/adr`, la carpeta de specs, etc., salvo aceptación expresa; si el proyecto ya guarda decisiones o specs en otro sitio, apuntar ahí.
- Las instrucciones dicen dónde están *hoy* decisiones, lecciones y specs, aunque no usen nombres de SFP.
- Si no hay sitio para lecciones sin crear carpetas, proponer un único archivo (p. ej. `LESSONS.md`) solo si el usuario acepta un archivo nuevo, o guardarlas fuera del repo.
- Verificación: `git status` debe mostrar solo los archivos acordados.

## sección 5 Producto repartido en varios repos (misma metodología)

Caso: un producto (p. ej. `api`, `web`, `mobile`, `contracts`, `infra`) vive en varios repos que deben compartir metodología. No es un monorepo: cada repo tiene su git, su CI y su ciclo de despliegue.

1. **Alcance.** Listar los repos con su papel y confirmar cuáles entran ahora. Se instala **una vez por repo** (cada uno con su análisis, su clasificación —los ejes A/B pueden variar— y su plan), en el orden que elija el usuario; mejor empezar por el de menor riesgo.
2. **Una sola fuente de la metodología:** la carpeta global (si existe) o un **repo de coordinación** (p. ej. `<producto>-meta`, o uno de los repos que elija el usuario). Cada repo la enlaza por ruta o URL desde su punto de entrada (`runtime-adapters.md`), sin copiarla. Sin ninguno de los dos, proponer uno; si el usuario no quiere, instalar en cada repo las mismas instrucciones autocontenidas y avisar de que habrá que sincronizarlas a mano.
3. **Qué va en cada sitio.**
   | Artefacto | Dónde |
   |---|---|
   | Spec de un cambio de un solo repo | En ese repo |
   | Spec de un cambio que cruza repos (contrato de API, evento, esquema) | En el repo **dueño del contrato**; los demás abren su propio cambio, que la enlaza (URL + commit) sin copiarla |
   | ADR de un solo repo | En ese repo |
   | ADR transversal (afecta a varios repos) | En el repo de coordinación; los afectados lo enlazan desde su `docs/adr/` (un ADR corto "ver <enlace>", o una línea en su índice) |
   | Lecciones | En el repo donde ocurrieron; las que se repiten entre repos pasan a la metodología global (regla normal de promoción) |
4. **Coherencia entre repos.** Mismo `skill_version` y misma variante de SFP (con o sin orquestador) en todos, salvo decisión explícita registrada como ADR transversal. Roles, tiers (niveles de modelo) y aprobaciones humanas pueden variar por repo si el usuario quiere.
5. **Manifiesto (registro de lo instalado).** Cada repo registra en `manifest.json.product` (sección 1 de `templates.md`) el nombre del producto, su papel, el repo de coordinación y la lista de repos (sin credenciales en las URLs). Así el modo Actualización y el Retiro saben qué repos revisar.
6. **Verificación.** `verify.sh` en cada repo, y comprobar a mano que los enlaces entre repos (specs y ADRs transversales) funcionan.
7. **Actualización.** Al subir de versión el skill, sus cambios (`CHANGELOG.md`) se evalúan repo por repo; se propone aplicarlos en todos por la coherencia del punto 4, pero cada repo se aprueba aparte.

---

## Casos límite

| Situación | Qué hacer |
|---|---|
| **Monorepo** | Preguntar alcance: raíz, un paquete o varios. Instrucciones generales en la raíz; por paquete solo si sus convenciones difieren. No duplicar. Perfil y etapa **por workspace** (sección 3.2 de `project-structure.md`); si conviven front y back, reglas de desempate D1–D10 (sección 3.1). |
| **Producto en varios repos** | Una instalación por repo, una sola fuente de metodología (carpeta global o repo de coordinación); specs y ADRs transversales en el repo dueño del contrato o en el de coordinación, enlazados (no copiados): sección 5. |
| **Windows sin `sh`** | `scripts/run.ps1` (Git Bash o WSL); si no hay ninguno, comprobaciones a mano, avisándolo en el plan y el reporte (`windows.md`). |
| **El usuario no aprueba el plan** | No se aplica nada; ofrecer exportarlo con el formato y la ubicación de la sección 16 de `templates.md` (fuera del repo salvo que pida otra cosa). |
| **Sin git** | Avisar; ofrecer `git init` o copia de los archivos a tocar. Sin respaldo no hay reestructuración. |
| **Muchas convenciones propias** | Mandan las del proyecto; la metodología se adapta con un ADR de desviación intencional (regla 2 del digest), no al revés. |
| **Instrucciones previas de otros runtimes** | Inventariarlas, no borrarlas. Sin contradicciones: una sola fuente que los demás archivos enlazan. |
| **Equipo con varios editores** | Una sola fuente de verdad y un adaptador por runtime (enlace simbólico, copia generada o referencia); documentar cómo regenerarlo. |
| **Entorno sin red** | No instalar herramientas externas; dejar instrucciones de instalación manual y marcar el paso pendiente. |
| **El usuario cambia de opinión** | Volver a la Fase 3, recalcular el plan y mostrar qué cambia. Si ya se aplicó algo, usar el manifiesto para ajustar. |
| **No existe la carpeta global** | Ofrecer crearla con las plantillas del skill (SYSTEM.md, methodology/, agents/); si no, instalar instrucciones mínimas autocontenidas y avisar. |
| **Secretos en el repo** | Informar que existen y su ruta, no su contenido; no incluirlos en el plan ni en el manifiesto. Recomendar cambiarlos; no actuar sin permiso. |
| **CI estricto** | Revisar sus reglas antes de proponer archivos nuevos; si los rechaza, usar ubicaciones permitidas o proponer ajustar el CI aparte, como riesgo alto. |
| **Repo enorme** | Análisis acotado (árbol superficial y muestreo); declarar lo no revisado. |
| **Archivos de solo lectura / permisos** | Parar y preguntar; no cambiar permisos. |
| **El orquestador elegido no tiene documentación accesible, es muy nuevo o no se puede verificar** | No suponer capacidades: ficha (sección B.1 de `orchestration.md`) con todo `PENDIENTE`, preguntar al usuario lo que sepa y no instalar ni configurar hasta que decida (alternativa: variante sin orquestador, sección A) |
| **El orquestador no soporta el sistema operativo o los runtimes del usuario** | Mostrarlo con la fuente; ofrecer otro orquestador o la variante sin orquestador; nunca forzar una instalación no soportada |
| **El orquestador no cubre un requisito de la entrevista (aislamiento, aprobación humana, memoria dentro del repo…)** | Compensar fuera de él si se puede y declarar el riesgo restante; si no, avisar y dejar que el usuario decida (tabla de decisión de la sección B.1 de `orchestration.md`) |
| **Instalación anterior detectada** | Pasar a modo Actualización: la sección 0 de `verify.sh` lista las entradas `[accion: si]` del CHANGELOG posteriores a la versión instalada; evaluar cada `aplica-si` y proponer solo esas. |
| **El usuario quiere desinstalar** | Modo Retiro: `uninstall.md` (primero dry-run, simulación sin cambios; `[MANUAL]` para lo editado tras instalar). |
| **Respuestas contradictorias** | Señalarlas y resolverlas antes de planificar. |
| **El usuario quiere "todo"** | Recordar el principio de contexto mínimo; proponer lo esencial y el resto como opcional. |
| **No hay herramienta madura de verificación de dependencias para el stack** | Usar como mínimo el script genérico de la sección 2 de `structure-verification.md`; decirlo en el reporte sin presentarlo como equivalente a una herramienta real. |
| **El proyecto ya tiene configurado `eslint-plugin-boundaries`/`import-linter`/ArchUnit/`packwerk`** | Reusarlo y adaptar sus reglas al perfil elegido; no instalar otra herramienta para lo mismo. |
