# Cuestionario de entrevista

Reglas: preguntar por bloques. Lo ya sabido con certeza solo se confirma (una línea). En cada pregunta técnica, ofrecer "no sé / decide por mí". Las opciones son ejemplos: siempre se admite "otro". Anotar respuestas.

## Bloque 0 — Intake (antes de todo lo demás)
0. ¿Tienes documentos del proyecto? Si es nuevo: blueprint, PRD o brief (visión o requisitos). Si existe: README, arquitectura o instrucciones para agentes. Procésalos según `intake.md` y confirma el **resumen de intake**. Salta lo que ya respondan con certeza (confirmándolo en una línea).

## Bloque 1 — Estado y objetivo
1. ¿El proyecto existe o empieza de cero? (Nuevo / Existente)
2. ¿Qué buscas con la metodología? (orden, calidad, trabajar con varios agentes, documentación, menos retrabajo, otro)
3. Solo si existe: ¿cuánto puede cambiar el repo (repositorio: el proyecto en git)?
   - **Solo metodología**: no crear ni mover carpetas del proyecto; lo mínimo, o fuera del repo.
   - **Integrar**: añadir archivos y carpetas nuevos sin mover nada existente.
   - **Reestructurar**: permitir mover y renombrar para alinearlo todo.
4. ¿Qué no se puede tocar? (carpetas, archivos generados, CI —comprobaciones automáticas—, carpetas o código de terceros)

## Bloque 2 — Proyecto
5. Tipo: web frontend, backend/API, fullstack, móvil, escritorio con tecnología web (Electron, Tauri), datos/ML, librería/SDK, infraestructura/DevOps, monorepo (varios proyectos en un repo), otro. Confirmar en una línea lo que dice `interfaz_web` en el análisis inicial.
5.1. Escala: ¿cuántos equipos lo mantendrán? ¿Habrá varios servicios, apps o módulos publicados por separado? ¿Cuántos módulos o funcionalidades prevés a medio plazo? Sirve para elegir perfil y etapa de `references/project-structure.md` (sección 3: estado actual → tipo → escala frente a la condición de Etapa 2 → contraste con el análisis inicial → propuesta; decide el usuario). No preguntar lo que ya dan las cifras de `discover.sh` (script de análisis inicial: `features_max`, `desplegables_estimados`): confirmarlo en una línea. Empate entre perfiles: sección 3.1. Monorepo: se pregunta por cada workspace o proyecto interno (sección 3.2). Si no lo sabe, asumir Etapa 1 y anotarlo como revisable.
6. Lenguajes, frameworks y gestor de paquetes.
7. Tamaño y madurez: prototipo, producción o legado. ¿Hay tests, linter (revisor de estilo), comprobación de tipos, CI?
8. Riesgo: ¿toca producción, auth (inicio de sesión), pagos, datos personales o contratos de API públicos? (Define las señales de alto riesgo y el rigor de los controles.)
9. ¿Trabajas solo o en equipo? ¿El equipo usa los mismos editores y agentes?
9.1. ¿El producto vive solo en este repo o en varios que deberían compartir metodología? Si son varios: ¿cuáles, qué papel tiene cada uno y hay (o quieres) un repo de coordinación? (sección 5 de `scenarios.md`)

## Bloque 3 — Herramientas y runtimes
10. ¿Qué editores (IDE) o herramientas de terminal (CLI) con agentes (runtimes) usas o usará el equipo? (p. ej. Claude Code, Codex, Cursor, Copilot, Windsurf, OpenCode, Gemini CLI, Kiro, Antigravity, Zed, JetBrains AI, otro). Puede ser más de uno.
11. ¿Qué modelos, proveedores y planes tienes? ¿Importa el coste? (sí/no). Sirve para asignar modelos reales a cada tier (nivel): Alta capacidad / Generalista / Ligero.
12. ¿Ya tienes configurados archivos de instrucciones, agentes, skills o MCP (conectores a herramientas)? ¿Quieres conservarlos tal cual?
13. ¿Existe una carpeta de metodología global (`~/sfp/` u otra)? ¿Dónde? ¿Quieres crearla con las plantillas del skill?

## Bloque 4 — Orquestación (decide caso 5 o 6)
14. ¿Quieres un orquestador (capa que coordina varios agentes: uno supervisa y delega, a veces en paralelo) o sesiones independientes?
    - Si "no sé": explicar en 3 líneas (con él: coordinación automática y memoria de trabajo, más piezas que mantener; sin él: más simple, lo compartido vive en los documentos de spec) y recomendar **sin orquestador** (lo más simple), aclarando que se puede añadir después.
15. Si orquesta: ¿cuál? (el que ya use o quiera; no se sugiere ninguno). ¿Ya está instalado? ¿Cuánto aislamiento necesitas? ¿Qué runtimes participarán?
    - **En cuanto lo nombre**, no basta: resolver el cuestionario de la sección B.1 de `orchestration.md` (documentación vigente → el propio orquestador, con permiso → el usuario) y volver con la ficha: lo que cubre, lo que cubre en parte y lo que no. Las preguntas 22 (aprobaciones), 23 (secretos y políticas) y 24 (lecciones) se contrastan con esa ficha.
16. Si no orquesta: ¿usarás varias sesiones a la vez? (Implica worktree —copia de trabajo aparte— o rama por sesión, y revisar en otra sesión.) Si trabaja con una sola sesión, explicar cómo será la revisión independiente según el riesgo (sección 8 de `development-practices.md`) y confirmar que revisará la persona los cambios de riesgo medio o alto.

## Bloque 5 — Especificación, agentes y calidad
17. ¿Usas o quieres una spec (descripción escrita del cambio) por cambio: propuesta → requisitos → diseño → tareas? ¿Con qué herramienta (la que ya uses o quieras; no se sugiere ninguna), o con documentos libres?
    - **En cuanto nombre una herramienta:** resolver la sección 1 de `tooling.md` (documentación vigente → la herramienta, con permiso → el usuario) y anotar el mapeo de sus archivos antes de planificar.
18. **Roles de agente (se definen conversando: sección 7 de `architecture.md`).** No ofrecer los 5 roles como lista cerrada. Pasos:
    a. ¿Cómo trabajas hoy con agentes? ¿Qué tareas se repiten? ¿Qué quieres separar (p. ej. programar y revisar)?
    b. Presentar una **recomendación mínima justificada** con el análisis inicial y las respuestas, más la alternativa más simple.
    c. El usuario acepta, quita, renombra o crea roles propios.
    d. Por cada rol aprobado, confirmar uno a uno: nivel o modelo por defecto, permisos mínimos y acciones que requieren aprobación humana.
    e. Mostrar la tabla final de roles y pedir confirmación.
19. ¿Qué funciones quieres cubrir con skills o herramientas (catálogo en la sección 6 de `architecture.md`)? ¿Ya usas alguna? Sin preferencia: ofrecer las candidatas de esa función, más "otra" y "ninguna", y solo las que cumplan su "Cuándo plantearla" según el análisis inicial (p. ej. frontend-design solo con frontend; Serena solo en un repo grande). Al elegir una, mostrar su fila de la sección 6.1 (qué hará y qué tiene prohibido) y aclarar para qué asistentes sirve el instalador `integrations.sh`: Claude Code (probado) y Codex (en pruebas: skills, Serena y Context7 en su `config.toml`, y RTK con su hook). Otros runtimes: instalación manual aprobada. Por defecto usa el gestor de paquetes del proyecto (`gestor_de_paquetes_js` del análisis inicial): confirmarlo en una línea, o preguntar si prefiere otro (npx, pnpm, bun o yarn 2+). Si el proyecto usa varios asistentes que el instalador admite, se ejecuta una vez por cada uno. Si nombra una (del catálogo o no): sección 2 de `tooling.md`.
20. Rigor de los controles de calidad (gates): ligero, estándar o estricto. ¿Qué comandos de lint, tests, tipos y seguridad usa hoy el proyecto?
20.1. ¿Dónde viven las pruebas? Si el análisis inicial muestra una carpeta de tests, confirmarla en una línea como convención (y, si lista tests fuera de ella, preguntar si se quiere ofrecer reordenarlos como tarea aparte). Si no hay carpeta ni patrón, ofrecer las opciones típicas del stack: carpeta dedicada en espejo, junto al archivo, o una por paquete en un monorepo. Las de integración y extremo a extremo van siempre en una carpeta aparte (sección 5 de `development-practices.md`).
20.2. Solo si el proyecto expone una API (REST u otra compatible con OpenAPI): ¿ya tiene un documento de OpenAPI o una herramienta que lo genere? Si lo tiene, se respeta; si no, ¿se genera desde el código o se mantiene un archivo junto a los endpoints? La herramienta que lo muestra la elige el equipo (sección 7 de `development-practices.md`).
20.3. ¿Quieres que el plan incluya una base del README con lo que ya se sabe del proyecto (o la adaptación del actual al formato recomendado, sin inventar nada) y que cada cambio no trivial diga qué cambia en él? (sección 9 de `development-practices.md`)
21. ¿Qué cambios son "no triviales" para ti? (Por defecto: varios archivos o módulos, cambio de comportamiento o de contrato, riesgo medio o alto.) Además: ¿un cambio pequeño que toque una señal de alto riesgo (auth, datos, producción, contratos de API) debe tratarse como no trivial? (Decisión abierta de SFP: sección 5 de `methodology-digest.md`.)

## Bloque 6 — Seguridad y gobernanza
22. ¿Qué acciones requieren siempre tu aprobación? (Por defecto: producción, destructivas, secretos, pagos, infraestructura crítica, borrados masivos, cambios globales o de metodología.)
23. ¿Hay secretos o datos sensibles en el repo o en el entorno de los agentes? ¿Políticas de la empresa que respetar?
23.1. No se pregunta: los commits y las PR salen siempre **sin firmas automáticas de agentes de IA** (sección 17 de `templates.md`; se instala en toda instalación). Solo se confirma en una línea en el cierre de la entrevista. Si los documentos del proyecto piden declarar la IA, decirlo: la declaración se hace con `Assisted-by`, que el filtro no toca.
24. ¿Registro de lecciones aprendidas: manual, automático (si el orquestador lo permite) o ninguno por ahora?

## Bloque 7 — Preferencias de aplicación
25. ¿Commits por bloque, un solo commit o ningún commit? ¿El repo ya tiene convenciones de git (mensajes, ramas, forma de fusionar, plantilla de PR)? Si el análisis avisó `remoto_con_credenciales`, decirlo sin mostrar el valor y proponer corregirlo. Confirmar lo que muestre el análisis (CONTRIBUTING, commitlint, historial). Si no hay, proponer los valores por defecto de `git-practices.md` y mostrar las reglas de SFP que mandan (sección 2) y las plantillas de mensajes legibles (sección 4), con su ejemplo.
26. ¿Prefieres antes un dry-run (solo ver el plan) o plan y aplicación en la misma sesión?
27. ¿Quieres un idioma concreto para los archivos generados? Si es español, se usa español neutro (regla inviolable 10: sin voseo ni regionalismos). Preguntar solo si prefiere tuteo o "usted" en los textos para personas.
28. ¿Dónde guardar el manifiesto (registro de lo instalado) y el reporte: en el repo, fuera o no guardar?
29. Si SFP mismo falla o se te ocurre una mejora del skill, ¿quieres que prepare el reporte para su repositorio y, con tu aprobación de cada uno, lo publique con `gh`? Solo si la Fase 0 comprobó que `gh` está instalado y con sesión iniciada; si no, decir cómo instalarlo y que se puede activar más adelante. Los reportes nunca incluyen datos del proyecto ("Reportar problemas y mejoras de SFP" en `SKILL.md`).

## Reglas de ramificación
- Roles: puede acabar con 0, 1 o varios, de los 5 base o propios; no insistir en completar el conjunto.
- "Nuevo" → saltar las preguntas 3, 4, 12 (en parte) y el análisis de código heredado.
- "Solo metodología" → no preguntar por carpetas nuevas de documentación; preguntar dónde prefiere las instrucciones (un archivo en la raíz, fuera del repo, o solo en la configuración personal del runtime).
- "Reestructurar" → añadir: ¿qué organización de carpetas quieres? ¿Hay builds, CI o imports que dependan de rutas? ¿Toleras rutas rotas un tiempo? ¿Quién más debe aprobar?
- Orquesta = sí → preguntas 14 y 15, más el cuestionario de la sección B.1 de `orchestration.md`; omitir la 16. Orquesta = no → 14 y 16; omitir la 15 y la sección B.1.
- Respuestas contradictorias → señalarlas y resolverlas antes de la Fase 3.

## Cierre de la entrevista
Resumir en lenguaje claro (regla inviolable 11) con una tabla: ejes A/B/C, runtimes, agentes, modelos por nivel, capa de specs, controles de calidad, reglas de aprobación y preferencias de aplicación. Preguntar "¿correcto?" y solo entonces pasar a la Fase 3.
