# Changelog — skill `spec-first-protocol` (antes `project-setup`)

Lo usa el modo Actualización (`SKILL.md`): compara `manifest.json.skill_version` con la versión más reciente de aquí y propone solo el delta (lo cambiado), sin reinstalar todo.

## Convención del delta (obligatoria desde 1.3.0, aplicada también a las versiones anteriores)

Cada versión tiene un resumen en prosa (para quien mantiene el skill) y una sección **Delta para proyectos ya instalados**, una línea por cambio, en uno de estos dos formatos:

```
- [accion: si] aplica-si: <condición comprobable en el manifiesto o el proyecto> · propuesta: <qué ofrecer al usuario, con referencia> · <qué cambió>
- [accion: no] <qué cambió> (solo afecta al skill o a instalaciones nuevas: nada que proponer)
```

- `verify.sh` sección 0 lista las líneas `[accion: si]` de las versiones posteriores a `skill_version`; la IA evalúa cada `aplica-si` contra el manifiesto y el proyecto y propone **solo** las que aplican, como ítems de un plan normal (Fases 4–7). Las `[accion: no]` no se mencionan al usuario salvo que pregunte.
- `aplica-si` usa campos del manifiesto (`templates.md` sección 1) o hechos comprobables; si no se puede evaluar, se pregunta al usuario.
- Las pruebas de mantenimiento (`project-setup-dev`, fuera del paquete) comprueban que toda entrada siga este formato.

## 1.16.4

Resumen: lo que la persona no debería tener que pedir, visto al usar la 1.16.3 en un proyecto real.
- Una decisión que todavía es una pregunta aparece en la tabla de la propuesta como "Pendiente de tu decisión", con la opción recomendada entre paréntesis, y no como si ya estuviera decidida.
- Git, siempre detectado y preguntado (decisión 26.1): la propuesta dice en qué situación está el proyecto (repositorio y rama, remoto, copia sin historial o sin Git, cuenta de `gh`) y pregunta sobre qué trabajar (esta carpeta, una rama nueva o un clon) y, si no hay remoto, dónde se publicará: el enlace de un repositorio existente, o crearlo, en qué cuenta y si privado o público. Si se elige clonar, la skill da los pasos sin que se los pidan. Crear el repositorio y subir algo llevan aprobación aparte.
- Reestructurar se muestra antes de decidir: junto a la pregunta va un adelanto del mapa antes → después (carpetas principales y lo que exige el framework), y el plan trae el mapa completo antes de mover nada. Elegir reestructurar basta: mapa, respaldo y aprobación van incluidos.
- La propuesta siempre pregunta qué asistentes se usarán (decisión 10), porque la skill solo ve el que la ejecuta: antes preparaba instrucciones solo para ese y olvidaba los demás. Con más de uno, propone una guía común (`AGENTS.md`) que los demás importen.

Delta para proyectos ya instalados:
- [accion: no] solo cambia la entrevista

## 1.16.3

Resumen: pedir empezar de nuevo vuelve a preguntar lo que es de la persona. En la práctica, al pedir "empieza el setup de 0", la skill reusó respuestas de antes y decidió sola integrar, sin preguntar.
- El registro de respuestas vale solo para lo dicho en la instalación en curso. Si la persona pide empezar de nuevo, se vacía: lo anterior solo puede aparecer como sugerencia, marcado como "lo que dijiste antes".
- Las decisiones que son de la persona, como integrar o reestructurar, nunca las responde el análisis.

Delta para proyectos ya instalados:
- [accion: no] solo cambia la entrevista

## 1.16.2

Resumen: integrar o reestructurar vuelve a ser siempre una decisión de la persona. La 1.16.1 dejaba integrar como valor por defecto y solo ofrecía reestructurar si la persona lo pedía, así que quien no sabía que podía pedirlo nunca lo veía.
- En un proyecto existente, la propuesta siempre pregunta, una sola vez, entre solo metodología, integrar o reestructurar, explicando cada opción en palabras simples. La skill recomienda según el análisis y dice por qué, pero no lo da por decidido.
- Reestructurar se explica como lo que es: aplicar a todo el proyecto las buenas prácticas de la skill (arquitectura de carpetas por funcionalidad y nombres estándar de `project-structure.md`), con respaldo obligatorio y el mapa antes → después, respetando lo que exija el framework.

Delta para proyectos ya instalados:
- [accion: no] solo cambia la entrevista de instalaciones nuevas y de cambios de configuración

## 1.16.1

Resumen: correcciones de la entrevista tras usarla en un proyecto real (una web Next.js con API pública y un pipeline Python).
- Nunca se propone reestructurar si no se va a mover nada: lo normal en un proyecto existente es integrar, y el perfil de estructura no aparece en la propuesta salvo que se reestructure.
- La instalación no cambia el producto: no agrega dependencias, cambios de código ni pasos nuevos de CI del proyecto. Si hacen falta (por ejemplo, para generar la documentación de la API), se anotan como primer cambio sugerido, que se hace después con su propia especificación.
- Contradicciones primero: `discover.sh` informa `copia_sin_historial: posible` cuando la carpeta no tiene Git pero sí CI o archivos de Git, y la propuesta recomienda trabajar sobre un clon para que el respaldo sea una rama. Nueva decisión 26.1 (respaldo) en la entrevista.
- La pregunta de aprobación se entiende sola: resume lo que se aprueba, dice que todavía no se escribe nada y qué viene después. Se prohíben en lo que ve la persona términos internos como "setup", "plan exacto", "espacios de trabajo", "etapa" o "tier", salvo explicados.

Delta para proyectos ya instalados:
- [accion: no] solo cambia la entrevista y el análisis de instalaciones nuevas

## 1.16.0

Resumen: la entrevista deja de ser un cuestionario. En la práctica preguntaba lo mismo varias veces, hacía demasiadas preguntas sin decir para qué servían, usaba jerga y preguntaba cosas que no aplicaban (por ejemplo, roles de agente sin orquestador).
- `references/interview.md` reescrito: primero se analiza el proyecto, después se presenta **una sola propuesta** con todas las decisiones ya completadas (del análisis, de los documentos o con un valor por defecto), cada una con qué significa para la persona y de dónde sale. La persona la aprueba o dice qué cambiar, en una respuesta.
- Solo se pregunta aparte lo que bloquea: no se puede deducir, cambia lo que se instala y no tiene un valor por defecto seguro. Como máximo 3 preguntas, en el mismo mensaje de la propuesta, cada una con una opción recomendada y su motivo.
- Registro de respuestas: lo respondido o aprobado no se vuelve a preguntar, ni con otras palabras; las preguntas pendientes no se repiten. Si un hallazgo cambia una decisión aprobada, se confirma solo esa.
- La tabla de decisiones conserva la numeración anterior (5.1, 20.1, 23.1…) y dice, para cada una, su valor por defecto y en qué caso se pregunta. Modelos, roles, lecciones, perfil de estructura, README, ubicación de las pruebas y rigor ya no se preguntan: van en la propuesta.
- El resumen de intake pasa a ser el primer apartado de la propuesta, sin ronda de preguntas propia. La Fase 3 ya no vuelve a confirmar la combinación.
- `tests/verificar_formato.py` comprueba que toda decisión de la entrevista citada en los documentos exista en `interview.md`.

Delta para proyectos ya instalados:
- [accion: no] solo cambia cómo se hace la entrevista en instalaciones, cambios de configuración y actualizaciones nuevas

## 1.15.0

Resumen: se atienden las 23 propuestas abiertas del repositorio.
- Reglas numeradas sin ambigüedad: las de `SKILL.md` se citan como "regla inviolable N" y las del resumen de la metodología como "regla N del resumen". Una prueba de formato rechaza cualquier "regla N" sin aclarar de qué lista es.
- Nuevo `references/development-practices.md` con las prácticas de trabajo diario, resumidas en el punto de entrada (secciones nuevas "Cómo se ejecuta un plan aprobado", "Pruebas", "Documentación" y "Revisión" de `templates.md` sección 3):
  - El plan aprobado se ejecuta de corrido, con revisión de cada fase; solo se detiene ante una falla real, algo no previsto o una acción que siempre requiere aprobación.
  - El asistente ejecuta los comandos permitidos en vez de pedírselos a la persona.
  - Antes de declarar algo inviable: restricciones externas, dos o tres alternativas probadas en el proyecto real y evidencia de cada intento. No se adelantan ítems del backlog.
  - Convención de dónde viven las pruebas (las de integración y extremo a extremo, siempre aparte) y pruebas escritas y ejecutadas mientras se construye.
  - Documento de OpenAPI como contrato de la API, actualizado en la misma tarea, sin imponer la herramienta que lo muestra.
  - README vivo: base al instalar y revisión en cada cambio no trivial, aprobada con el plan.
  - Revisión independiente con una sola sesión: sesión nueva según el riesgo, revisión de la persona en riesgo medio o alto, y el resumen dice qué revisión hubo.
  - Memoria a largo plazo: estado de ADR y lecciones, índices de lo vigente y revisión al archivar y al actualizar. Nada se borra por antigüedad.
- Entrevista: preguntas 20.1 (pruebas), 20.2 (OpenAPI) y 20.3 (README); la 16 explica la revisión con una sola sesión. Plantillas de lección (campo Estado) y de revisión (tipo de revisión y comprobaciones nuevas). Lista de cobertura ampliada.
- `discover.sh` informa `tests_fuera_de_carpetas_de_tests` y los `contratos_de_api` (OpenAPI o Swagger) que encuentre.
- Dos modos nuevos en `SKILL.md`: **Cambio de configuración** (nivel de intrusión, coordinación o rigor, sin reinstalar: muestra lo actual, comprueba lo que requiere el cambio y solo planifica lo afectado) y **Agregar un asistente** (genera las instrucciones del runtime nuevo reutilizando las decisiones ya tomadas).
- `verify.sh` compara la versión registrada y las copias fijas del skill dentro del proyecto con la instalación global (la carpeta se puede indicar con `SFP_GLOBAL_SKILL_DIR`) y avisa si quedaron atrás. Solo informa: nada se actualiza solo.
- Filtro de firmas de IA que no viajaba al clonar: la sección 17 de `templates.md` lo versiona en `.githooks/` (salvo en el nivel "solo metodología") y lo activa en cada copia con `git config core.hooksPath .githooks` (paso escrito en el README del proyecto). La nueva sección 5 de `verify.sh` da una FALLA si el filtro está en el repositorio pero no está activo en esa copia, con el comando para activarlo, y avisa si solo vive en `.git/hooks/`.
- Código de salida 3 en CI: `verify.sh` explica al terminar qué significa su código y cómo tratarlo en un pipeline; `--strict-tooling` convierte el 3 en 1. Ejemplo listo para GitHub Actions en `examples/ci/verificar-sfp.yml`.
- Proyectos sin Git: la Fase 5 ofrece `git init` o una copia de respaldo fuera del proyecto con fecha, registrada en `backup` del manifiesto; en una reestructuración no se aplica nada sin una de las dos. El README lo explica en sus preguntas frecuentes.
- Documentación que no confirma un cambio: la regla inviolable 8 fija el comportamiento por defecto (no aplicar, informar, ofrecer la alternativa que no depende del asistente y anotarlo como "No hecho: no se pudo verificar"), también en la capa A de la sección 17 de `templates.md` y en la sección 2 de `tooling.md`.
- Herramientas complementarias:
  - `integrations.sh --agent codex` (en pruebas): instala las skills en `.agents/skills` o `~/.agents/skills` (Codex no lee `.claude/skills`) y guarda su estado en `.sfp/integrations-codex.json`. Serena (contexto `codex`) y Context7 se registran en `[mcp_servers.<nombre>]` de `.codex/config.toml` (Codex solo lo lee en proyectos de confianza) o de `~/.codex/config.toml`, añadiendo la tabla sin reescribir el resto; RTK, con `rtk init -g --codex`. El retiro llama al CLI de skills sin `--agent`, porque con un asistente concreto no borra la carpeta compartida `.agents/skills`; si la misma skill también está en `.claude/skills`, queda `[MANUAL]` para no borrar la copia de Claude Code. Claude Code sigue siendo el camino probado. (Durante el desarrollo se probó OpenCode, pero se reemplazó por Codex porque es el asistente que se usará junto a Claude Code.)
  - `integrations.sh --runner auto|npx|npm|pnpm|bun|yarn`: el CLI de skills se puede ejecutar con npx o con npm (`npm exec`), que era lo que pedía la issue 1, y también con pnpm, bun o yarn; `auto` usa el gestor del proyecto (`packageManager` o lockfile). `discover.sh` informa `gestor_de_paquetes_js` e `interfaz_web`. npx, npm y pnpm, probados de punta a punta (instalar, comprobar y retirar); bun y yarn, en pruebas.
  - Nueva candidata **modern-web-guidance** (Google Chrome, v1.0.2, Apache-2.0), solo con interfaz web (ahora también Electron y Tauri), con su fila en la matriz de la sección 6.1 de `architecture.md`. Instalación, comprobación y retiro probados. La versión fijada es la del texto de la skill: para consultar sus guías ejecuta `npx -y modern-web-guidance@latest`, con red, y eso se dice antes de proponerla.
  - Nueva candidata **Context7** (documentación vigente de librerías): `integrations.sh --only context7` la instala con versión fijada (`@upstash/context7-mcp@4.9.0`) en Claude Code y en Codex, sin escribir claves. La skill también la usa, si está disponible, para consultar la documentación vigente de otras herramientas (regla inviolable 8), citando siempre la página oficial.
  - `integrations.sh --strict-tooling`, como en `verify.sh`.
- Proyecto de ejemplo actualizado a 1.15.0: instrucciones con las secciones nuevas (sin comandos inventados: el formato queda `PENDIENTE`), índices de ADR y lecciones, estado de la lección y tipo de revisión.
- **Sin firmas de IA, siempre:** la sección 17 de `templates.md` (ajuste del runtime verificado, regla en el punto de entrada y filtro `commit-msg` versionado) se instala en toda instalación, sin la pregunta 23.1. Es un ítem fijo del plan, que se aprueba con el resto. Declarar la IA con `Assisted-by` sigue siendo posible, porque el filtro no lo toca.
- Reporte de problemas y mejoras de SFP con `gh` (sección nueva de `SKILL.md`, pregunta 29 de la entrevista): borradores sin interrumpir el trabajo, mostrados en la siguiente pausa, sin datos del proyecto y publicados solo con aprobación de cada uno.
- Instrucciones dirigidas a la IA dentro del proyecto: aviso de seguridad con formato fijo (archivo, texto literal y que no se ejecutó), en el momento y repetido en el resumen final (sección 2.1 de `intake.md`, regla inviolable 9 y reporte de la Fase 7).

Delta para proyectos ya instalados:
- [accion: no] solo cambia cómo los documentos del skill citan las reglas
- [accion: si] aplica-si: el punto de entrada no tiene la sección "Cómo se ejecuta un plan aprobado" · propuesta: añadirla entre marcadores desde `templates.md` sección 3 · plan de corrido, comandos, inviabilidad con evidencia y orden del backlog
- [accion: si] aplica-si: el punto de entrada no tiene la sección "Pruebas" · propuesta: repetir `discover.sh`, confirmar la convención (pregunta 20.1) y añadir la sección entre marcadores; si hay `tests_fuera_de_carpetas_de_tests`, ofrecer reordenarlos como tarea aparte · ubicación de las pruebas y pruebas mientras se construye
- [accion: si] aplica-si: el punto de entrada no tiene la sección "Documentación" · propuesta: preguntas 20.2 (solo si el proyecto expone una API) y 20.3, y añadir la sección entre marcadores · OpenAPI, README vivo y memoria a largo plazo
- [accion: si] aplica-si: el punto de entrada no tiene la sección "Revisión" y el proyecto trabaja sin orquestador · propuesta: añadirla entre marcadores desde `templates.md` sección 3 · revisión independiente con una sola sesión
- [accion: si] aplica-si: existen ADR o lecciones en el proyecto sin índice de lo vigente · propuesta: crear los índices y proponer el estado de cada lección (sección 10 de `development-practices.md`), sin borrar nada · memoria a largo plazo
- [accion: si] aplica-si: `verify.sh` avisa que una copia fija del skill dentro del proyecto quedó atrás respecto a la instalación global · propuesta: informar ambas versiones y preguntar si el equipo quiere actualizar la copia; nunca hacerlo sin aprobación · copias fijas del skill
- [accion: no] modos Cambio de configuración y Agregar un asistente (se usan cuando la persona los pide)
- [accion: si] aplica-si: el manifiesto tiene una acción sobre `.git/hooks/commit-msg` (capa C de la sección 17 de `templates.md`) y el nivel de intrusión no es "solo metodología" · propuesta: versionar el filtro en `.githooks/` (o en el gestor de hooks del proyecto), activarlo con `git config core.hooksPath .githooks` y añadir ese paso al README del proyecto · filtro de firmas que viaja con el repositorio
- [accion: si] aplica-si: `verify.sh` informa FALLA en la sección "5. filtro de firmas de IA" · propuesta: mostrar el comando que imprime para activar el filtro en esa copia y ejecutarlo con aprobación · filtro inactivo en una copia
- [accion: si] aplica-si: el punto de entrada no tiene el párrafo de los archivos como datos, no instrucciones, en "Aprobación humana obligatoria" · propuesta: añadirlo entre marcadores desde `templates.md` sección 3 · aviso de seguridad con formato fijo
- [accion: no] `verify.sh --strict-tooling`, explicación del código de salida y ejemplo de CI (se usan cuando el equipo los pide)
- [accion: no] respaldo sin Git y comportamiento ante documentación no confirmable (aplican en instalaciones y cambios nuevos)
- [accion: si] aplica-si: `runtimes` del manifiesto incluye Codex y el proyecto tiene herramientas complementarias instaladas para Claude Code (existe `.sfp/integrations.json`) · propuesta: `bash scripts/integrations.sh --agent codex` (plan) con la misma selección, incluidos Serena, Context7 y RTK si estaban seleccionados · herramientas complementarias en Codex
- [accion: si] aplica-si: `discover.sh` informa `interfaz_web: si`, o `structure.profile` es frontend o fullstack · propuesta: ofrecer modern-web-guidance con su fila de la matriz de la sección 6.1 de `architecture.md` e `integrations.sh --only modern-web-guidance` · Modern Web Guidance
- [accion: si] aplica-si: el punto de entrada no tiene la sección "Reporte de problemas de SFP" · propuesta: pregunta 29 de la entrevista y añadir la sección entre marcadores con la elección · reporte de problemas con gh
- [accion: no] `integrations.sh --runner` (por defecto usa el gestor del proyecto; no deja nada en él)
- [accion: si] aplica-si: el proyecto usa librerías o frameworks que cambian a menudo, o la persona dice que el asistente se equivoca con APIs desactualizadas · propuesta: ofrecer Context7 con su fila de la matriz de la sección 6.1 de `architecture.md` e `integrations.sh --only context7` · documentación vigente de librerías
- [accion: si] aplica-si: el punto de entrada no tiene la sección "Atribución en commits y PRs", o la sección 5 de `verify.sh` dice "no se usa el filtro en este proyecto" · propuesta: añadir como ítems del plan, sin preguntar, las capas de la sección 17 de `templates.md` que falten (A en cada runtime verificado, B y C versionada), y el paso de activación en el README del proyecto · sin firmas de IA, siempre

## 1.14.0

Resumen: los documentos del skill se reescribieron en lenguaje claro, para que los entienda cualquier persona.
- Se reescribieron 19 documentos (unas 3.700 líneas), incluidos los dos textos completos de la metodología: frases más cortas, listas en lugar de párrafos densos y cada término técnico explicado la primera vez que aparece en cada documento. Los anglicismos se tradujeron o se explicaron.
- No cambió ninguna regla, paso, número, nombre de archivo, comando, bloque de código ni marcador. La numeración de las secciones sigue igual. Se comprobó automáticamente contra la versión anterior y con todas las pruebas de los scripts.

Delta para proyectos ya instalados:
- [accion: no] solo cambia la redacción de los documentos del skill

## 1.13.0

Resumen: todo se escribe para personas reales, también los documentos del propio skill.
- Se reemplazó el signo de párrafo, usado como abreviatura de "sección", por la palabra: "sección 4", "secciones 2 a 5". Fueron 444 apariciones en 23 archivos, incluidos los mensajes que muestran los scripts. Las guías de terceros incluidas quedan sin tocar.
- La regla de lenguaje claro ya no exime a los archivos internos: el repositorio es público y los leen personas. Cuando un documento remite a otro, lo nombra con palabras y resume en una línea qué dice.

Delta para proyectos ya instalados:
- [accion: no] solo cambia el texto de los documentos y mensajes del skill

## 1.12.0

Resumen: nombres de rama legibles y tres reglas de seguridad para los remotes (repos remotos).
- Ramas: un solo formato, que une los dos de las fuentes. El prefijo es el mismo tipo que los commits; la descripción dice el efecto; solo minúsculas, números y guiones, sin tildes; el ticket solo si el equipo lo usa; nada de nombres de personas, fechas ni palabras vacías; menos de ~50 caracteres. Incluye ejemplos de nombres mal y bien puestos.
- Remotes: nunca contraseñas ni tokens (claves de acceso) en la dirección del remote; antes de cada push (envío) se dice adónde va y qué sube; agregar, cambiar o borrar remotes requiere aprobación. Las reglas de forks (copias de repos ajenos) quedan fuera a propósito.
- `discover.sh` avisa `remoto_con_credenciales` si una dirección https guarda usuario o token; solo dice cuántas, nunca el valor.
- Sección "Git" del punto de entrada y pregunta 25 actualizadas.

Delta para proyectos ya instalados:
- [accion: si] aplica-si: `discover.sh` informa `remoto_con_credenciales` · propuesta: avisar sin mostrar el valor, proponer el gestor de credenciales o SSH y recomendar cambiar el token · credenciales en remotes
- [accion: si] aplica-si: la sección "Git" del punto de entrada no tiene las líneas de ramas legibles y remotes · propuesta: añadirlas desde `templates.md` sección 3 entre marcadores · ramas y remotes

## 1.11.0

Resumen: lenguaje claro y no técnico en todo lo que lee una persona.
- Regla inviolable 11 de `SKILL.md`. Respuestas, preguntas, planes, reportes, documentos, commits y PRs se escriben para alguien que no conoce el código. Primero qué pasa y qué significa; jerga explicada o evitada; frases cortas. Nada de referencias que nadie va a seguir (secciones, rutas internas, líneas, hashes, "ver X"): se explica lo que dicen.
- Plantillas de mensajes: la referencia al ticket pasa a ser opcional y solo si el equipo la usa; "Cómo probarlo" con pasos que cualquiera puede seguir.
- El reporte final, el resumen del plan y el cierre de la entrevista se escriben en lenguaje claro. La sección "Idioma" del punto de entrada pasa a "Idioma y claridad".

Delta para proyectos ya instalados:
- [accion: si] aplica-si: el punto de entrada tiene sección "Idioma" sin la regla de lenguaje claro · propuesta: reemplazarla por "Idioma y claridad" de `templates.md` sección 3 entre marcadores · lenguaje claro

## 1.10.0

Resumen: mensajes de commit, PR y merge (fusión) legibles para quien no vio el código.
- Sección 4 de `git-practices.md`: 8 reglas. El asunto dice el efecto, no cómo se hizo. El cuerpo empieza por el problema. "Qué cambia" se escribe desde quien usa el sistema. Se dice qué NO cambia. Se incluye "Cómo probarlo" y la referencia, sin jerga. Un cambio trivial se queda solo con el asunto.
- Plantillas con ejemplo para el commit, la descripción de PR (Por qué · Qué cambia · Qué NO cambia · Cómo probarlo · Riesgos) y el commit de merge, más una revisión previa. La plantilla propia del repo manda si existe.
- Nueva fila en sección 2: en un cambio no trivial, el cuerpo del commit es obligatorio (0xbigboss lo deja como opcional).
- Sección "Git" del punto de entrada (sección 3 de `templates.md`) y pregunta 25 actualizadas.

Delta para proyectos ya instalados:
- [accion: si] aplica-si: la sección "Git" del punto de entrada no menciona mensajes legibles · propuesta: añadir la línea de mensajes legibles de `templates.md` sección 3 entre marcadores · mensajes legibles

## 1.9.0

Resumen: español neutro obligatorio.
- Regla inviolable 10 de `SKILL.md`: en español, las respuestas, los archivos generados, los commits y las PRs van en español neutro, con tuteo o "usted". Nunca voseo ("vos", "tenés", "podés", "hacé"…) ni regionalismos, aunque el usuario los use.
- Sección "Idioma" en el punto de entrada (sección 3 de `templates.md`), para que la cumpla cualquier agente que trabaje en el proyecto. Pregunta 27 de la entrevista y checklist de cobertura actualizados.

Delta para proyectos ya instalados:
- [accion: si] aplica-si: el punto de entrada del proyecto no tiene sección "Idioma" y el idioma acordado es español · propuesta: añadir la sección "Idioma" de `templates.md` sección 3 entre marcadores · español neutro

## 1.8.0

Resumen: buenas prácticas de git (commits, ramas, merge, PRs, versiones) **sin reinventarlas**.
- `references/vendor/` incluye sin modificar `git-workflow-and-versioning` de addyosmani/agent-skills (MIT) y `git-best-practices` más `git-examples` de 0xbigboss/claude-code (Apache-2.0), con sus licencias, commit de origen y huellas (`vendor/README.md`).
- `references/git-practices.md` adapta las fuentes a SFP. Prioridad: política del repo, luego SFP, luego las fuentes. Reglas de SFP que mandan sobre las fuentes: el agente no hace commits por su cuenta; nada de `reset --hard` sin aprobación; los worktrees (copias de trabajo) los decide la orquestación; los controles de calidad usan los comandos reales; push, merge, force-push y tags requieren aprobación; descubrir ramas sin depender de `gh`. Resuelve la contradicción sobre squash (unir commits) entre ambas fuentes.
- Sección "Git" en el punto de entrada (sección 3 de `templates.md`), pregunta 25 ampliada, catálogo 7.55 en `SKILL.md`, checklist de cobertura y README.

Delta para proyectos ya instalados:
- [accion: si] aplica-si: el punto de entrada del proyecto no tiene sección "Git" · propuesta: confirmar las convenciones del repo (pregunta 25) y añadir la sección "Git" de `templates.md` sección 3 entre marcadores · convenciones de git

## 1.7.0

Resumen: opción neutral (vale para cualquier agente) para que commits y PRs salgan **sin firmas automáticas de agentes de IA**.
- Sección 17 de `templates.md`: tres capas independientes. A. Ajuste de cada runtime (entorno del agente), solo si su documentación lo confirma (Claude Code: `attribution` con `commit`/`pr` vacíos y `sessionUrl: false`; `includeCoAuthoredBy` está obsoleto). B. Regla neutral en el punto de entrada. C. Hook `commit-msg` neutral (script que revisa el mensaje).
- Nuevo `scripts/hooks/commit-msg-ai-attribution.sh` (POSIX sh + awk), fuente única del hook. Quita trailers (líneas al final) `Co-Authored-By` de agentes conocidos (por nombre o dominio de correo), líneas "Generated/Created with/by" que nombran a un agente y trailers como `Claude-Session:`. No toca el asunto, los coautores humanos, `Signed-off-by` ni `Assisted-by`. Se salta con `SFP_KEEP_AI_ATTRIBUTION=1`.
- Dónde instalar el hook según el repo: `.git/hooks`, husky, gestores de hooks o `core.hooksPath` local. `core.hooksPath` global queda prohibido por defecto, porque anula los hooks de todos los repos; para todos se ofrece `init.templateDir`, que es global y `[MANUAL]`.
- Entrevista 23.1 (pregunta antes si alguna política exige declarar la IA), catálogo 7.6 de `SKILL.md`, checklist de cobertura y fila de retiro en `uninstall.md`.

Delta para proyectos ya instalados:
- [accion: si] aplica-si: el usuario pide quitar la atribución de IA de commits o PRs, o el proyecto tiene un hook o una regla propia con ese fin sin marcadores de SFP · propuesta: entrevista 23.1 y las capas elegidas de `templates.md` sección 17 como ítems de plan (Fases 4-7) · atribución de IA

## 1.6.2

Resumen: documentación para publicar el repositorio.
- `README.md`: qué es, requisitos, instalación, uso, fases, integraciones, scripts, estructura, actualización y retiro, seguridad, contribución y licencias de terceros.
- `LICENSE` (MIT) y `.gitignore`.
- El encabezado de `SKILL.md` usa el nombre actual de la skill.

Delta para proyectos ya instalados:
- [accion: no] documentación y licencia del repositorio (solo afecta al skill)

## 1.6.1

Resumen: correcciones de la revisión final de 1.6.0.
- `integrations.sh` registra lo que instala en `.sfp/integrations.json` (selección y registros); `--check` y el nuevo `--uninstall` lo reutilizan. El retiro deshace lo del proyecto y deja lo global como `[MANUAL]` con su comando exacto.
- RTK en el proyecto se detecta por su bloque `<!-- rtk-instructions` (antes bastaba cualquier mención de "rtk").
- La detección de frontend ignora carpetas generadas (`.archify`, `htmlcov`, `coverage`, `site`, `_build`, `target`, `.sfp`).
- Versiones de rtk (1.2.1) y uv (0.13.9) fijadas también en winget y en los instaladores `curl | sh`; en macOS, el instalador oficial con versión en lugar de brew.
- Una entrada `serena` existente que no respeta la sección 6.1 se reporta como `[CONFLICTO]` (antes se daba por configurada). En el proyecto, Serena siempre se registra con `uvx`, que es portable.
- El modo plan devuelve 3 si queda incompleto. Exige bash ≥ 4 de forma explícita. `.mcp.json` conserva su sangría.
- Documentación: sección 6.2 reescrita (solo Claude Code, bash, global frente a proyecto, estado, relación con el manifiesto); `RTK_DISABLED=1` en las Fases 1/7 y en el Retiro; `rtk bypass` en lugar del alias obsoleto `rtk proxy`; referencias `superpowers:*` aclaradas en la sección 6.1.
- Otros: `verify.sh` devuelve 3 si falta el respaldo; `manifest_tool.py` y los ayudantes imprimen UTF-8 en la consola de Windows; `.gitattributes` fija LF en `.sh` y `.py`; nombre antiguo `project-setup` retirado de los textos (no del esquema del manifiesto, por compatibilidad).

Delta para proyectos ya instalados:
- [accion: si] aplica-si: el proyecto tiene skills o MCP instalados con `integrations.sh` 1.6.0 (no existe `.sfp/integrations.json`) · propuesta: ejecutar `bash scripts/integrations.sh --apply` con la misma selección para registrarlos (lo ya presente no se reinstala) y, si RTK está activo, añadir `RTK_DISABLED=1` a los comandos de evidencia del punto de entrada · estado de integraciones
- [accion: no] correcciones internas de `integrations.sh`, `verify.sh`, `lib.sh` y documentación del skill

## 1.6.0

Resumen: integración de cinco candidatas conocidas (Superpowers en subconjunto, Serena, RTK, archify y frontend-design) sin solaparse.
- La sección 6 de `architecture.md` las nombra por función. Sección 6.1: matriz única de enrutamiento (quién hace qué: disparador → responsable → prohibido): SFP manda en specs, planes, tareas, sub-agentes, worktrees, revisión, gates y memoria. Sección 6.2: el instalador.
- De Superpowers solo se instalan 5 skills sueltas (`test-driven-development`, `systematic-debugging`, `verification-before-completion`, `receiving-code-review`, `finishing-a-development-branch`); nunca el plugin ni su hook `SessionStart`.
- Nuevo `scripts/integrations.sh` (Bash): versiones fijas, detección global/proyecto, repetible sin efectos extra, plan por defecto, `--apply` y `--check` (estado).
- Alineados: regla 3 de `SKILL.md`, `tooling.md`, entrevista 19, plantilla del punto de entrada (sección 3) y checklist del digest (resumen). Nueva decisión abierta 7 del digest: TDD (pruebas primero) frente al orden de gates.
- Correcciones de la auditoría: `verify.sh` ya no devuelve 0 ("sin fallas") sin manifiesto o sin git (ahora 3, incompleto); `discover.sh` informa `python` cuando Python 3 solo existe con ese nombre (Windows); `run.ps1` acepta `integrations` y usa `bash` en WSL.
- Convivencia con la entrada 1.3.0 de neutralidad de herramientas: sigue vigente para **orquestadores y herramientas de specs**, y para todo archivo instalado que presente un producto como parte de SFP. Las candidatas del catálogo no son parte de SFP: se instalan como opciones con su fila de la matriz, así que esa entrada no les aplica.

Delta para proyectos ya instalados:
- [accion: si] aplica-si: el proyecto usa alguna de las cinco candidatas (aparece en `.claude/skills/`, `.mcp.json`, la configuración del runtime o el punto de entrada) sin la sección "Skills/herramientas y precedencia" de `templates.md` sección 3 · propuesta: añadir esa sección entre marcadores con las filas de `architecture.md` sección 6.1 de las herramientas presentes, y ejecutar `scripts/integrations.sh --check` · matriz de enrutamiento
- [accion: si] aplica-si: existe el plugin `superpowers` habilitado, o skills de Superpowers excluidas por sección 6.1 (`brainstorming`, `writing-plans`, `executing-plans`, `subagent-driven-development`, `dispatching-parallel-agents`, `using-git-worktrees`, `requesting-code-review`, `using-superpowers`, `diagnosing-superpowers`, `writing-skills`) · propuesta: mostrar el solapamiento con SFP y ofrecer (decisión humana) desinstalar el plugin y dejar solo el subconjunto de sección 6.1 vía `integrations.sh` · solapamiento Superpowers
- [accion: no] `verify.sh` devuelve 3 sin manifiesto o sin git; `discover.sh` detecta `python`; `run.ps1 integrations` (solo afecta a los scripts del skill)

## 1.5.2

Resumen: `SKILL.md` documenta dos buenas prácticas para distribuir el skill: autocontenido siempre, e instalación global como fuente de verdad (copia en el proyecto solo fija y justificada).

Delta para proyectos ya instalados:
- [accion: no] sección "Distribución del skill" en `SKILL.md` (solo afecta al skill)

## 1.5.1

Resumen: probado en Linux (Debian 12 con `dash`, Alpine 3.20 con BusyBox, y Alpine solo con `jq`, sin Python). Corrige dos fallos que en Windows no se veían:
- `sfp-section.sh` no encontraba ninguna sección con `mawk` (el `awk` por defecto de Debian/Ubuntu no admite `{2,3}`).
- Con el `grep` de BusyBox (sin `--exclude-dir` ni `-I`) fallaban en silencio la búsqueda de marcadores en `verify.sh` y `discover.sh`, la detección de nombres antiguos y la **búsqueda de credenciales filtradas** de `discover.sh`, que no avisaba de ninguna aunque las hubiera. Ahora usan `find` + `grep -l`, que funciona en todos.
- La parte de `jq` queda probada.

Delta para proyectos ya instalados:
- [accion: si] aplica-si: el discovery de ese proyecto se hizo en un sistema con BusyBox (p. ej. Alpine o un contenedor mínimo) · propuesta: repetir `discover.sh` y revisar las secciones `riesgos-secretos` y `setup-previo`, que pudieron salir vacías por error · detección de credenciales y marcadores en BusyBox
- [accion: no] `sfp-section.sh` con `mawk`; pruebas en contenedores Linux en `project-setup-dev/linux/`

## 1.5.0

Resumen: nombres propios de la metodología en lugar de "ai".
- En los proyectos: carpeta `.sfp/` (antes `.ai-setup/`), marcadores `sfp:start` / `sfp:end` (antes `ai-setup:start/end`), etiqueta de respaldo `pre-sfp` (antes `pre-ai-setup`), plan exportado `sfp-plan-*.md` (antes `ai-setup-plan-*.md`).
- Carpeta global de ejemplo `~/sfp/` (antes `~/ai/`; sigue siendo solo un ejemplo, y `discover.sh` aún detecta `~/ai` si existe).
- Variables de los scripts `SFP_*` (antes `AI_SETUP_*`).
- `discover.sh` y `verify.sh` detectan instalaciones con los nombres antiguos.

Delta para proyectos ya instalados:
- [accion: si] aplica-si: existe `.ai-setup/`, o `discover.sh` informa `instalacion_con_nombres_antiguos` · propuesta: con aprobación y tras un punto de retorno, renombrar `.ai-setup/` a `.sfp/` (`git mv`), cambiar en cada archivo listado los marcadores `ai-setup:start`/`ai-setup:end` por `sfp:start`/`sfp:end` (solo esas líneas), y en el manifiesto `backup.ref` si era `pre-ai-setup` (el tag puede quedarse con su nombre o crearse `pre-sfp` en el mismo commit); luego `fingerprint.sh --propose` / `--accept` para refrescar las huellas de los bloques fusionados y `verify.sh` · nomenclatura sfp
- [accion: no] carpeta global de ejemplo `~/sfp/` y variables `SFP_*` de los scripts (nada en los proyectos)

## 1.4.1

Resumen: paquete más limpio. Las pruebas de los scripts (`scripts/tests/run.sh`), las evaluaciones de la IA (`scripts/tests/evals/`) y la guía `references/self-test.md` salen de la skill a una carpeta aparte, `project-setup-dev`. Solo sirven para mantenerla: nunca se usan al preparar un proyecto. `run.ps1` deja de ofrecer `tests`.

Delta para proyectos ya instalados:
- [accion: no] pruebas y evaluaciones movidas fuera del paquete; nada cambia en los proyectos ni en el flujo

## 1.4.0

Resumen:
- Esquema formal del manifiesto (`references/manifest.schema.json`), validado por `scripts/manifest_tool.py check` desde `verify.sh` (erratas, huellas mal copiadas, ids repetidos, reglas entre campos).
- `fingerprint.sh --propose/--accept` genera el manifiesto con las huellas para revisarlo y aprobarlo, sin copiarlas a mano.
- `configure` con `format: json` registra los cambios clave por clave (`changes`); el retiro los revierte solo donde siguen como los dejó la instalación.
- `discover.sh` reconoce capas con nombres en español o portugués y en mayúscula (.NET), carpetas con `*.csproj` y la raíz real de proyectos Java/Kotlin.
- Evaluaciones del comportamiento de la IA (`scripts/tests/evals/`), con cabecera plana obligatoria en el plan exportado.

Delta para proyectos ya instalados:
- [accion: si] aplica-si: `verify.sh` informa FALLA en la sección "E. esquema del manifiesto" · propuesta: corregir cada campo señalado (erratas, formato de huellas, ids repetidos) como ítems de plan; si el manifiesto es `schema: 1`, migrarlo a `schema: 2` · manifiesto validado
- [accion: si] aplica-si: hay acciones create/merge sin `sha256` · propuesta: `fingerprint.sh --propose`, revisar la propuesta con el usuario y `--accept`; huellas que difieren solo con `--refresh` y confirmación expresa · huellas sin copia manual (sustituye al procedimiento manual de 1.3.0)
- [accion: si] aplica-si: hay acciones `configure` sobre archivos JSON sin `format`/`changes` · propuesta: añadir `"format": "json"` y calcular `changes` con `fingerprint.sh --propose` (contra `backup.ref`) para que el retiro sea automático · retiro de JSON clave por clave
- [accion: si] aplica-si: `structure.rationale` se basó en una clasificación `indeterminado` de `discover.sh` en un proyecto con capas en español, .NET o Java · propuesta: repetir `discover.sh` y re-evaluar perfil/etapa (`project-structure.md` sección 3) · detección de capas ampliada
- [accion: no] cabecera plana obligatoria del plan exportado (`templates.md` sección 16), `scripts/tests/evals/`, nuevas pruebas en `scripts/tests/run.sh`

## 1.3.0

Resumen:
- Señales de estructura en `discover.sh`; perfiles por workspace en monorepos y reglas de desempate; producto repartido en varios repos.
- Modo Retiro con procedimiento y `uninstall.sh` (por defecto solo simula), apoyado en huellas sha256.
- Esta convención de delta; ficha del orquestador y plan exportado con formato fijo; lanzador PowerShell para Windows; pruebas automáticas de los scripts.
- Neutralidad de herramientas de specs y skills en SFP (como el orquestador en 1.2.0).
- Índice por pregunta de los textos SFP.
- `verify.sh` y `fingerprint.sh` aceptan `python` como Python 3 (habitual en Windows) y normalizan finales de línea `\r\n`.

Delta para proyectos ya instalados:
- [accion: si] aplica-si: alguna acción create/merge del manifiesto no tiene `sha256` · propuesta: ejecutar `scripts/fingerprint.sh`, mostrar el resultado y registrar la huella solo de los ítems que el usuario confirme sin cambios desde el setup (o sin cambios según `git diff <backup.ref>`); añadir `id=` a los marcadores de esos bloques (`templates.md` secciones 1 a 2, `uninstall.md` sección 1) · sin huellas el retiro no puede ser automático
- [accion: si] aplica-si: `structure.profile` es `monorepo` y no hay `structure.workspaces` · propuesta: decidir perfil y etapa por workspace (`project-structure.md` sección 3.2) y registrarlos · monorepo con varios perfiles
- [accion: si] aplica-si: `structure.profile` existe y `structure.rationale` no cita una cifra de `discover.sh` ni una regla D1–D10 · propuesta: re-evaluar con la sección `estructura-de-codigo` de `discover.sh` y las reglas de `project-structure.md` secciones 3 a 3.1; proponer cambio solo si el resultado difiere · decisión de perfil/etapa reproducible
- [accion: si] aplica-si: el proyecto usa una capa de especificación y el manifiesto no tiene `spec_layer` · propuesta: resolver `tooling.md` sección 1 y registrar herramienta y mapeo de artefactos · capa de specs neutral
- [accion: si] aplica-si: el punto de entrada u otros archivos instalados presentan una herramienta de specs o un skill concreto como parte de SFP · propuesta: reescribir esa parte por función, entre marcadores (`templates.md` sección 3) · neutralidad de herramientas
- [accion: si] aplica-si: existe `classification.orchestrator_profile` sin las 15 claves de área · propuesta: rehacer la ficha con el formato de `templates.md` sección 15 (repite `orchestration.md` sección B.1 solo para lo que falte o esté `PENDIENTE`) · ficha con formato fijo
- [accion: si] aplica-si: el usuario indica que el producto vive en varios repos · propuesta: `scenarios.md` sección 5 y campo `product` del manifiesto en cada repo · producto multi-repo
- [accion: no] `schema: 2` del manifiesto: `verify.sh` sigue aceptando `schema: 1`; se sube al añadir cualquiera de los campos nuevos
- [accion: no] nueva sección `estructura-de-codigo` en `discover.sh`; sección `specs` sin nombres de herramienta como implementación
- [accion: no] `uninstall.sh`, `fingerprint.sh`, `lib.sh`, `sfp-section.sh`, `run.ps1`, `scripts/tests/run.sh`, `references/uninstall.md`, `references/windows.md`, `references/tooling.md`, `references/sfp-index.md`
- [accion: no] plan exportado con nombre, ubicación y contenido fijos (`templates.md` sección 16)
- [accion: no] `verify.sh`: valida `structure.workspaces`, rutas fuera del proyecto, huellas (informativo) y lista este delta; acepta `python` como Python 3

## 1.2.0

Resumen:
- Orquestador neutral (sección B.1 de `orchestration.md`): cuestionario de 15 áreas con fuente y fecha, sin citar ningún orquestador concreto.
- Fallos de `verify.sh`: sin `jq` decía "sin fallas" sin verificar; columnas desplazadas en acciones sin `path`; ejecutaba `verify_command` sin permiso; respaldo fijo en `pre-ai-setup`; no mostraba archivos nuevos sin commit.
- `discover.sh` sin duplicados ni avisos de `find`.
- Erratas en `templates.md`, `interview.md` y `runtime-adapters.md`.

Delta para proyectos ya instalados:
- [accion: si] aplica-si: `classification.orchestration` no es `none` y no existe `classification.orchestrator_profile` · propuesta: resolver `orchestration.md` sección B.1, presentar la ficha (`templates.md` sección 15) y guardarla en el manifiesto · descubrimiento del orquestador
- [accion: si] aplica-si: el punto de entrada instalado asume capacidades de un orquestador concreto sin ficha · propuesta: sustituir por el bloque "Orquestador" de `templates.md` sección 3, entre marcadores · orquestador agnóstico
- [accion: si] aplica-si: existe un `gates.yml` instalado con la clave `señales_alto_riesgo` · propuesta: renombrarla a `senales_alto_riesgo` · clave sin ñ
- [accion: si] aplica-si: hay acciones `move` sin `from` en el manifiesto · propuesta: completar `from` con la ruta de origen (del plan o de `git log --follow`) · `actions[].from`
- [accion: no] correcciones de `verify.sh` y `discover.sh` (se usan al ejecutar; no dejan nada en el proyecto)
- [accion: no] erratas en `interview.md` y `runtime-adapters.md`

## 1.1.1

Resumen: sección 3 de `project-structure.md`, procedimiento de 6 pasos para decidir perfil y etapa (con paso 0, estado actual del proyecto); campo `manifest.json.structure.rationale`.

Delta para proyectos ya instalados:
- [accion: si] aplica-si: existe `structure.profile` y `structure.rationale` está vacío · propuesta: completar `rationale` con la situación actual y la condición que decidió (`project-structure.md` sección 3, paso 5) · justificación registrada
- [accion: no] `interview.md` 5.1 y `SKILL.md` 1.5 apuntan al procedimiento

## 1.1.0

Resumen:
- Perfiles de estructura de código por tipo de proyecto y etapa (`project-structure.md`).
- Verificación de la regla de dependencia (`structure-verification.md`).
- `verify.sh`, `self-test.md` y plantilla `gates.yml`.
- Campos `skill_version` y `structure` del manifiesto.

Delta para proyectos ya instalados:
- [accion: si] aplica-si: el manifiesto no tiene `structure` y el usuario no declaró usar su propia estructura · propuesta: ofrecer perfil y etapa (`project-structure.md` sección 3) y su verificación (`structure-verification.md`), como ítems opcionales · perfil de estructura
- [accion: si] aplica-si: no existe `gates.yml` ni un archivo de gates/CI equivalente · propuesta: ofrecer la plantilla de `templates.md` sección 14 con los comandos reales del proyecto · quality gates ejecutables
- [accion: si] aplica-si: el manifiesto no tiene `skill_version` · propuesta: añadirlo con la versión vigente al terminar la actualización · versión registrada
- [accion: no] `verify.sh`, `self-test.md` y cambios de `architecture.md`, `interview.md`, `scenarios.md`, `methodology-digest.md`

## 1.0.0

Resumen: versión base. Instalador de SFP para cualquier entorno (con/sin orquestador), 8 fases, análisis reproducible (`discover.sh`), roles de agente definidos conversando con el usuario, catálogo opcional de qué instalar.

Delta para proyectos ya instalados:
- [accion: no] versión base: no hay instalaciones anteriores
