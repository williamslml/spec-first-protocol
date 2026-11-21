# Resumen (digest) de las reglas prácticas de la metodología

Versión de este resumen y del skill `spec-first-protocol`: `../CHANGELOG.md` (registro de cambios). El modo Actualización (`SKILL.md`) compara `manifest.json.skill_version` con la versión actual del CHANGELOG y propone solo lo nuevo.

Es el **resumen práctico** de SFP. El texto completo, con diagramas y justificaciones, está en `sfp-con-orquestador.md` y `sfp-sin-orquestador.md` (ante una duda, mandan esos). Sirve para redactar los puntos de entrada sin perder reglas, comprobar la cobertura (sección 4) y saber qué cambia entre variantes: con o sin orquestador (herramienta que coordina varios agentes). Las diferencias solo se indican donde la regla cambia.

## 1. Reglas que deben llegar al proyecto

| # | Regla |
|---|---|
| 1 | **Separación de capas**: metodología → (orquestación) → agentes → modelos → runtime/CLI (programa que ejecuta al agente) → skills → tools; nada se ata a un proveedor, modelo, runtime u orquestador concreto; las capas se nombran por función, no por herramienta |
| 2 | **Quién manda en cada tema**: alcance y decisiones críticas = humano; estado del software = Git/archivos; reglas del proyecto = ADRs (registros de decisiones de arquitectura)/docs; metodología global = carpeta global; ejecución técnica de un agente = runtime/configuración. Desviación intencional del proyecto → ADR |
| 3 | **Trivial o no trivial**: no trivial = varios archivos o módulos, cambia comportamiento o contratos, riesgo medio/alto → exige un artefacto de especificación versionado antes de escribir código; trivial → directo, con verificación básica |
| 4 | **Spec frente a ADR**: la spec (especificación) dice *qué* se construye (vive mientras el change, o cambio en curso, está activo; luego se archiva); el ADR explica *por qué* se tomó una decisión de arquitectura (permanente). El diseño de un change solo pasa a ADR si la decisión afecta a todo el proyecto; nunca documentar la misma decisión dos veces |
| 5 | **Tiers (niveles) de modelo**: Alta capacidad (riesgo o complejidad altos), Generalista (trabajo normal), Ligero (simple, bajo riesgo; worker o agente completo, ubicado según su rendimiento real). Los modelos y los % (ejemplo 50/30/20) son del usuario, no cuotas rígidas |
| 6 | **Señales de alto riesgo** predefinidas (ej.: producción, autenticación, datos, contratos de API) → Alta capacidad. No equivalen a las acciones que requieren aprobación humana: son listas distintas, fijas, que pueden solaparse |
| 7 | **Escalamiento** Ligero → Generalista → Alta capacidad según evidencia (errores, bloqueos, incertidumbre, riesgo, complejidad, resultados insuficientes) |
| 8 | **Revisión crítica**: separar quien implementa de quien valida (sin orquestador: en otra sesión, con otro modelo/runtime; recibe specs + `tasks.md` + diff, no el chat) |
| 9 | **Ciclo de funcionalidad importante**: Alta capacidad define arquitectura y división en partes → propose (propuesta) → (reparto) → implementación según `tasks.md` → integración/revisión → archive (archivo) → Git |
| 10 | **Controles de calidad (quality gates)** proporcionales al riesgo: trivial = implementación + verificación básica; crítico = tests + types + lint + security + architecture + regression + documentation + review. Evitar burocracia |
| 11 | **Mínimo privilegio** (solo los permisos necesarios) y flujo DETECT → PROPOSE → REVIEW → APPROVE → EXECUTE para: producción, operaciones destructivas, secrets, pagos, infraestructura crítica, borrado masivo, cambios globales o de metodología |
| 12 | **Contexto mínimo**: no cargar lo que el agente no necesita; progressive disclosure (detalle solo cuando hace falta); recuperación just-in-time (en el momento justo); jerarquía GLOBAL → PROJECT → AGENT → TASK → SESSION |
| 13 | **Memoria**: el chat es temporal; el conocimiento permanente vive en Git, ADR, docs, runbooks y la carpeta global |
| 14 | **Git** = fuente de verdad del software; **ADR** con Status/Context/Decision/Alternatives/Consequences/References; **runbooks** (guías paso a paso) para procedimientos repetibles |
| 15 | **Lecciones**: formato "Aplica cuando: …", solo lo no obvio; pasan a global solo si son recurrentes, generales, valiosas, aplicables a varios proyectos, de coste razonable, sin complejidad desproporcionada y validadas; guía: no promover hasta ~3 apariciones **independientes** (con orquestador, algunos usan `recall >= 3`, que cuenta recuperaciones y no apariciones independientes: sección 5); un agente nunca modifica la metodología global por su cuenta |
| 16 | **Cambios en la metodología global**: proceso formal (Approval → carpeta global → commit → versión), carpeta versionada en Git |
| 17 | **Anti-crecimiento**: no generalizar ni complicar de más; añadir complejidad solo si la experiencia lo exige; metodología viva (Template → proyecto real → experiencia → validación → refinamiento → conocimiento reutilizable) |
| 18 | **Observabilidad**: métricas iniciales y evaluación por tipo de tarea (evals = futuro) |

## 2. Los 22 principios fundamentales (títulos)
1 agnóstico de agente · 2 de modelo · 3 de runtime · 4 de orquestador y herramienta de especificación (sin orquestador: solo herramienta de especificación) · 5 consciente del proyecto · 6 Git fuente de verdad · 7 ADRs = decisiones, spec = ejecución de una funcionalidad, nunca ambos para lo mismo · 8 docs = conocimiento del proyecto · 9 chat temporal · 10 progressive disclosure · 11 contexto mínimo · 12 mínimo privilegio · 13 control humano en decisiones críticas · 14 evolución basada en evidencia · 15 no globalizar experiencias aisladas · 16 complejidad solo si está justificada · 17 medir el sistema · 18 separar ejecución de validación · 19 capacidades especializadas solo cuando sean relevantes · 20 metodología global ligera · 21 conocimiento reutilizable validado antes que instrucciones duplicadas · 22 herramientas maduras antes que metodología adicional para lo mismo.

En el punto de entrada de un proyecto **no** copiar los 22 principios: resumir en 8–12 líneas las reglas de uso diario (1, 3, 4, 6, 8, 10, 11, 12 de la tabla) y remitir a la carpeta global del usuario si existe (si no, las instrucciones deben ser autocontenidas).

## 3. Qué cambia entre variantes

| Aspecto | CON orquestador | SIN orquestador |
|---|---|---|
| Capa de orquestación | Supervisor + workers (agentes ejecutores); patrones de coordinación; el orquestador lo elige el usuario y sus capacidades y límites se averiguan con la sección B.1 de `orchestration.md` (no se suponen) | No existe; se puede añadir después entre METHODOLOGY y AGENTS sin rediseñar el resto |
| Reparto de trabajo | El supervisor decide agente/modelo y paraleliza, siguiendo las listas fijas (alto riesgo y alto impacto) | Selección por criterios de tiers; cada sesión es independiente |
| Estado compartido | Lo gestiona el orquestador | `tasks.md` y la spec; no depende de ningún chat |
| Revisión | Parte del flujo de la capa | Sesión separada, otro modelo/runtime; recibe specs + tasks + diff |
| Paralelismo | Workers en paralelo | Un git worktree (copia de trabajo aparte) o rama por sesión paralela |
| Permisos | Restricciones de herramientas del orquestador, con el alcance que confirme su ficha (si aísla menos de lo que exige el riesgo, compensar) | Configurar el mínimo necesario en **cada** runtime antes de usarlo |
| Lecciones | Autoaprendizaje opcional (opt-in) del orquestador (memoria operativa) + `docs/lessons/` como fuente de verdad | Registro manual en `docs/lessons/` al archivar un change relevante |
| Métricas | Según el orquestador | Anotación manual por tarea |
| Aprobación al promover | Al aplicar la promoción, revisada como PR (solicitud de cambios) | Siempre humana |
| Glosario | Incluye la fila Orchestration Layer | No la incluye; métricas = registro manual |

## 4. Checklist (lista) de cobertura: usar en la Fase 4 y en el reporte final

Para **cada** fila, marcar: `Instalado` · `Ya existía (ruta)` · `Omitido por decisión del usuario` · `N/A (motivo)`. Nada puede quedar sin marcar.

- [ ] Instrucciones de proyecto por runtime (reglas 1–3, 6, 8, 10–12 resumidas)
- [ ] Estructura de conocimiento: `docs/adr`, `docs/runbooks`, `docs/lessons`
- [ ] Capa de especificación y los 4 artefactos por change; límite con el ADR
- [ ] Carpeta global (SYSTEM.md; methodology/, agents/, skills/, tools/ solo si procede); versionada en Git
- [ ] Capa de enlace por runtime y cómo regenerarla
- [ ] Plantillas de agentes (solo los roles elegidos)
- [ ] Tiers de modelo asignados + señales de alto riesgo + escalamiento
- [ ] Lista de acciones de alto impacto (aprobación humana) distinta de la de alto riesgo
- [ ] Controles de calidad ajustados a los comandos reales
- [ ] Permisos y mínimo privilegio configurados (por runtime o por orquestador)
- [ ] Orquestación (solo con orquestador) con su ficha de la sección B.1 de `orchestration.md` completa, o guía de sesiones independientes y worktrees (sin orquestador)
- [ ] Registro de lecciones (formato "Aplica cuando") y regla de promoción
- [ ] Métricas (según la variante)
- [ ] Skills/herramientas elegidas por el usuario (no por defecto), con su fila de la matriz de enrutamiento (sección 6.1 de `architecture.md`) copiada al punto de entrada y la comprobación `scripts/integrations.sh --check` en verde
- [ ] Idioma y claridad en el punto de entrada (en español: neutro, sin voseo ni regionalismos; lenguaje claro, sin referencias que nadie va a seguir)
- [ ] Convenciones de Git acordadas (`git-practices.md`): las del repositorio o los valores por defecto, en la sección "Git" del punto de entrada
- [ ] Atribución de IA en commits/PRs (sección 17 de `templates.md`): capas elegidas, o "N/A: no se pidió" o "política exige declararla"
- [ ] Manifiesto (lista de lo instalado) y respaldo/rollback
- [ ] Decisiones documentadas como ADR cuando el proyecto se desvió de un valor por defecto global
- [ ] Perfil y etapa de `project-structure.md` elegidos (o "N/A: usuario usa su propia estructura")
- [ ] Verificación de la regla de dependencia (`structure-verification.md`): herramienta real, script de respaldo, o `PENDIENTE` explícito

## 5. Decisiones abiertas de SFP y cómo las trata el setup (instalación)

Huecos de la metodología **sin respuesta única**. El setup los resuelve con el usuario y los registra (ADR de desviación o `PENDIENTE:`); no los presenta como regla.

| # | Decisión abierta | Tratamiento en el setup |
|---|---|---|
| 1 | "No trivial" (regla 3) y "señales de alto riesgo" (regla 6) son listas distintas y no dicen cuál manda. Un cambio de una línea en autenticación es trivial por el primer criterio y Alta capacidad por el segundo | Preguntar (entrevista 21) y fijar en las instrucciones cuál manda (propuesta: la señal de alto riesgo vuelve no trivial el cambio) |
| 2 | El reparto usa **señales fijas** y a la vez un juicio multicriterio (complejidad, ambigüedad, coste, historial…) | Señales fijas = mínimo obligatorio (Alta capacidad); los demás criterios solo para elegir entre Ligero y Generalista |
| 3 | Ligero se describe como "simple y bajo riesgo" y también como "worker completo, complejidad baja/media" | Definir su alcance con el usuario según su rendimiento real |
| 4 | El ejemplo 50 % Alta capacidad / 30 / 20 contradice "Alta capacidad solo donde el riesgo lo justifica" | No usar porcentajes como objetivo; omitirlos o dejarlos `PENDIENTE` hasta tener métricas |
| 5 | "Recurrencia ~3 veces" se cuenta distinto: apariciones independientes (manual) vs `recall >= 3` de un orquestador (recuperaciones) | Usar "independientes" en `docs/lessons/` (campo Recurrencia de la plantilla) en ambas variantes |
| 6 | Datos volátiles de herramientas (proveedores que admite un orquestador, número de asistentes compatibles con una herramienta de specs, rutas de memoria) | Verificar en la documentación vigente antes de usarlos (orquestador: cuestionario de la sección B.1 de `orchestration.md`); nunca copiarlos a las instrucciones del proyecto, solo la fuente y la fecha de verificación |
| 7 | TDD (escribir los tests antes del código) vs orden de controles "implementación → tests" | Por defecto en el skill: los tests escritos primero son parte del paso de implementación, y el control de tests sigue ejecutando la suite completa después; el orden de controles no cambia. Si el usuario quiere otro orden, registrar un ADR de desviación (sección 6.1 de `architecture.md`) |

## 6. Complemento: piezas de SFP que el skill debe conocer

- **Ciclo de vida:** Idea → Planning → Architecture → Design → Implementation → Testing → Security → Quality → Deploy → Documentation → Maintenance. La profundidad de cada fase depende del riesgo; Planning/Architecture/Design viven en el ciclo de la capa de specs (propose → design → tasks); Implementation ejecuta los ítems de `tasks.md`.
- **Controles de calidad, en orden:** tasks.md → implementación → tests → lint/format (estilo y formato) → tipos → seguridad → coherencia de arquitectura → regresión → documentación → revisión final → hecho. No todos siempre.
- **Cambio trivial:** salta la capa de specs y va directo a elegir agente/modelo con verificación básica; es la misma metodología con menos profundidad, no un camino aparte.
- **Memoria:** sesión (chat, temporal) → proyecto (Git, ADR, docs, runbooks, lecciones) → global (solo lo generalizable y validado).
- **Promoción a global:** conocimiento de proyecto → lección → validación humana → ¿recurrente/generalizable? → análisis de impacto → cambio global propuesto → aprobación → carpeta global → commit → versión.
- **Capas (glosario):** Spec Layer (planificación por funcionalidad), Methodology, Agents (quién), Models (capacidad), Runtimes (entorno), Skills (capacidades especializadas) y Tools (instrumentos), Git, ADRs, Project Docs, Runbooks, Metrics, Lessons Learned, carpeta global; Orchestration Layer solo en la variante con orquestador. Skill ≠ tool: un skill puede usar varias tools y al revés.
- **Project Setup (este skill):** conecta la metodología global con un proyecto concreto; no copia la carpeta global.
