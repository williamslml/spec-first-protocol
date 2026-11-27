# Entrevista: primero una propuesta, después solo lo que bloquea

La entrevista no es un cuestionario. Su fin es completar las decisiones de la instalación, y casi todas se deducen del análisis del proyecto o tienen un valor por defecto razonable. Por eso no se hacen preguntas una por una: se presenta **una sola propuesta** con todo ya decidido, la persona la aprueba o cambia lo que quiera, y solo se pregunta aparte lo que de verdad bloquea.

## 1. Cómo se hace (obligatorio)

1. **Analizar antes de preguntar.** Con la salida de `discover.sh`, los documentos del proyecto (sección 1 de `intake.md`) y lo que ya se sabe de la sesión: el asistente que está ejecutando la skill no se pregunta, se sabe.
2. **Completar cada decisión** de la sección 3 con, en este orden: lo que la persona ya dijo, un hecho del análisis o el valor por defecto de la tabla.
3. **Presentar una sola propuesta** con el formato de la sección 2. Incluye el resumen de lo entendido (el resumen de intake de `intake.md`) y todas las decisiones. La persona responde una vez: aprueba o dice qué cambiar.
4. **Preguntar aparte solo lo que bloquea** (sección 4), dentro del mismo mensaje de la propuesta: como máximo 3 preguntas, nunca en rondas sueltas antes ni después.
5. **Registro de respuestas.** Lo que la persona respondió o aprobó queda fijo para toda la instalación:
   - No se vuelve a preguntar, ni con otras palabras.
   - Mientras haya preguntas sin responder, no se vuelven a mostrar ni se suman otras: se espera, o se sigue con lo que no depende de ellas.
   - Si un hallazgo posterior cambia una decisión ya aprobada, se dice en una línea qué cambió y por qué, y se pide confirmar solo esa decisión.
6. **Lenguaje claro** (regla inviolable 11): cada decisión y cada pregunta dice en una línea qué decide para la persona. Sin jerga sin explicar. Cada pregunta trae una opción **recomendada**, con su motivo en pocas palabras, y la opción "decide por mí". No usar términos internos de la skill en lo que ve la persona: "setup", "plan exacto", "espacios de trabajo", "workspace", "etapa", "perfil", "tier", "gates", "capa" o "intrusión", salvo explicados en la misma frase.
7. **La instalación no cambia el producto.** Se instalan instrucciones, documentos de trabajo y, si se aprueban, herramientas del catálogo. Nunca se agregan en la propuesta dependencias o librerías del proyecto, cambios de su código ni pasos nuevos de su CI: si hacen falta (por ejemplo, para generar la documentación de la API), se anotan como **primer cambio sugerido**, que se hará después con su propia especificación.
8. **Contradicciones primero.** Si el análisis o los documentos se contradicen (por ejemplo, `copia_sin_historial: posible` en el análisis: hay CI de GitHub pero la carpeta no tiene Git), se dice en "Lo que entendí" y se recomienda cómo resolverlo antes de planificar (aquí: trabajar sobre un clon con Git, para que el respaldo sea una rama).

## 2. Formato de la propuesta

```markdown
### Lo que entendí del proyecto
<3 a 6 líneas: qué es, cómo se construye y se prueba, qué ya tiene. Lo deducido se marca como deducido.>
<Si hay contradicciones entre los documentos y el repositorio, una línea por cada una.>

### Cómo propongo instalar SFP
| Decisión | Propuesta | Qué significa para ti | De dónde sale |
|---|---|---|---|
| <nombre corto> | <valor> | <una línea> | análisis · tus documentos · valor por defecto · lo que dijiste |

Herramientas opcionales que encajan con el proyecto (no se instalan si no las pides): <lista corta, o "ninguna">.

### Lo que necesito que decidas
<Solo si hay algo que bloquea (sección 4). Si no, se omite este apartado.>
1. <Pregunta>. Decide <qué>. Recomiendo <opción>, porque <motivo>. Otras: <opciones> · decide por mí.

¿Lo apruebas así o cambias algo? Basta con decir qué cambiar.
```

**La pregunta de aprobación se entiende sola.** La herramienta de preguntas suele tapar el texto de arriba, así que la pregunta repite en una o dos líneas lo principal que se aprueba, dice que todavía no se escribe nada y qué viene después. Por ejemplo: "Propongo: añadir instrucciones comunes para Codex y Claude Code sin mover nada, controles estrictos en cambios de riesgo y especificaciones en `specs/`. ¿Lo apruebas? Después te muestro la lista de archivos que crearía o cambiaría, y tampoco se escribe nada hasta que la apruebes." Opciones: "Sí, muéstrame la lista de archivos" (recomendada) y "Quiero cambiar algo".

La propuesta no escribe nada: las Fases 0 a 4 siguen siendo de solo lectura. Aprobada, se pasa a la Fase 3 y al plan de cambios de la Fase 4, sin volver a preguntar lo decidido.

## 3. Decisiones, valor por defecto y cuándo se pregunta

El número de cada decisión se conserva porque otros documentos lo citan ("decisión 20.1", "pregunta 20.1").

| N.º | Decisión | De dónde sale o valor por defecto | Se pregunta solo si |
|---|---|---|---|
| 0 | Documentos del proyecto | Se leen los que haya (README, docs, instrucciones); se piden una sola vez, en la Fase 0 | Nunca como pregunta aparte; si no hay, se sigue |
| 1 | Proyecto nuevo o existente | Análisis | Nunca |
| 2 | Qué se busca con SFP | No se pregunta: se instala SFP completo y se respeta lo que la persona haya dicho | Nunca |
| 3 | Cuánto puede cambiar el repositorio | **Lo decide siempre la persona** (regla inviolable 7). En un proyecto existente es una de las preguntas de la propuesta, con las tres opciones explicadas en palabras simples: **solo metodología** (no crea ni mueve carpetas), **integrar** (añade lo nuevo sin mover nada) o **reestructurar** (reorganiza todo el proyecto con las buenas prácticas de la skill: arquitectura de carpetas por funcionalidad y nombres estándar, según `project-structure.md`, con respaldo obligatorio y el mapa antes → después). La recomendación sale del análisis y se dice por qué, pero nunca se da por decidida. Nuevo: no aplica | Siempre, en un proyecto existente, salvo que la persona ya lo haya dicho |
| 4 | Qué no se puede tocar | Análisis: carpetas generadas, de terceros y la CI | Los documentos o la persona mencionan otra restricción |
| 5 | Tipo de proyecto | Análisis (`interfaz_web`, `estructura-de-codigo`) | El análisis no lo deja claro y cambia la propuesta |
| 5.1 | Arquitectura de carpetas y nombres | Si se eligió reestructurar: el perfil y la etapa que salen del análisis (sección 3 de `project-structure.md`), con la regla que los decidió, respetando lo que exija el framework (p. ej. `app/` en Next.js). Si no se reestructura: no se toca la estructura y no aparece en la propuesta | Nunca como pregunta aparte; va en la propuesta y en el mapa antes → después del plan |
| 6, 7 | Tecnologías, madurez, pruebas y CI | Análisis | Nunca |
| 8 | Señales de alto riesgo | Las del análisis (producción, inicio de sesión, pagos, datos personales, API pública) más la lista por defecto | Nunca; van en la propuesta |
| 9 | Una persona o un equipo | Una persona, salvo que el análisis muestre varias (CODEOWNERS, varios autores recientes) | Nunca; va en la propuesta |
| 9.1 | Producto repartido en varios repositorios | Un solo repositorio | La persona lo menciona (sección 5 de `scenarios.md`) |
| 10 | Asistentes que se usan | El que ejecuta la skill y los que ya tienen instrucciones en el repositorio | Nunca; va en la propuesta |
| 11 | Modelos por nivel | Sin reglas por modelo: se usa el modelo disponible | La persona dice que usa varios modelos o que le importa el costo |
| 12 | Configuración que ya existe | Se conserva siempre; lo nuevo se añade con marcadores | Nunca |
| 13 | Carpeta de metodología global | Instrucciones completas dentro del proyecto | El análisis encuentra una carpeta global (se propone usarla) |
| 14, 15, 16 | Orquestador y sesiones | Sin orquestador, una sesión a la vez | La persona nombra un orquestador o pide sesiones en paralelo |
| 17 | Cómo se escriben las especificaciones | La herramienta que detecte el análisis; si no hay, documentos simples en `specs/` | La persona nombra una herramienta que el análisis no detectó (sección 1 de `tooling.md`) |
| 18 | Roles de agente | Ninguno fijo; la revisión sigue la sección 8 de `development-practices.md` | Hay orquestador, sesiones en paralelo o un equipo, y la persona quiere roles (sección 7 de `architecture.md`) |
| 19 | Herramientas complementarias | Ninguna; las que encajan se listan como opcionales en la propuesta | La persona elige alguna (entonces, su fila de la sección 6.1 de `architecture.md` y el instalador con el gestor de paquetes del proyecto) |
| 20 | Rigor de los controles de calidad | Estándar, con los comandos que el proyecto ya tiene; estricto en los cambios que tocan una señal de alto riesgo | Nunca; va en la propuesta |
| 20.1 | Dónde viven las pruebas | La carpeta que detecte el análisis; si no hay, la convención del framework (sección 5 de `development-practices.md`) | Hay pruebas repartidas de varias formas y ninguna predomina |
| 20.2 | Documentación de la API | Solo si el proyecto expone una: lo que ya exista. Si no hay nada, se anota la convención (generarla desde el código o un archivo junto a los endpoints, sección 7 de `development-practices.md`), y crearla queda como primer cambio sugerido: la instalación no agrega dependencias ni toca el código | Nunca; va en la propuesta |
| 20.3 | README | Añadir con marcadores lo que falte, sin reescribir lo que hay (sección 9 de `development-practices.md`) | Nunca; va en la propuesta |
| 21 | Qué cambios llevan especificación | El criterio de SFP (varios archivos, cambia el comportamiento o un contrato, riesgo medio o alto), y un cambio que toca una señal de alto riesgo también la lleva | Nunca; va en la propuesta |
| 22 | Acciones que requieren tu aprobación | La lista por defecto: producción, operaciones destructivas, secretos, pagos, infraestructura crítica, borrados masivos, cambios globales o de metodología | Nunca; va en la propuesta |
| 23 | Secretos y datos sensibles | Análisis (sección `riesgos-secretos`): se avisa de su existencia, nunca de su contenido | Nunca |
| 23.1 | Firmas de IA en commits y PR | Se quitan siempre (sección 17 de `templates.md`) | Nunca |
| 24 | Lecciones aprendidas | Registro en el proyecto (`docs/lessons/`), que se crea al anotar la primera | Nunca |
| 25 | Convenciones de Git | Las del repositorio; si no hay, las de `git-practices.md`. El asistente propone los commits y no los hace por su cuenta | Nunca; va en la propuesta. Si el análisis avisa `remoto_con_credenciales`, se dice sin mostrar el valor |
| 26 | Ver el plan antes de aplicar | Siempre: el plan se aprueba antes de escribir nada | Nunca |
| 26.1 | Respaldo | Con Git, una rama o etiqueta antes de escribir. Sin Git: si el análisis dice `copia_sin_historial: posible`, recomendar trabajar sobre un clon; si no, `git init` o una copia fuera del proyecto (Fase 5 de `SKILL.md`) | Nunca; va en la propuesta, y la contradicción en "Lo que entendí" |
| 27 | Idioma de los archivos | El de la persona; en español, neutro y con tuteo | Nunca |
| 28 | Dónde se guarda el registro de lo instalado | `.sfp/` dentro del proyecto | La persona pide no dejar rastros en el repositorio |
| 29 | Reporte de problemas de SFP con `gh` | Desactivado; si `gh` está listo, se menciona en una línea que se puede activar | Nunca |

## 4. Qué cuenta como pregunta que bloquea

Una decisión se pregunta aparte solo si cumple las tres condiciones:
1. No se puede deducir del análisis, de los documentos ni de lo que dijo la persona.
2. Cambia lo que se va a instalar o el riesgo de hacerlo.
3. No tiene un valor por defecto seguro.

Siempre bloquea, en un proyecto existente: **integrar o reestructurar** (decisión 3), porque cambia todo lo que se va a hacer y es una decisión de la persona (regla inviolable 7). Se pregunta una vez, en la propuesta, salvo que ya lo haya dicho.

Otros ejemplos de lo que sí bloquea: una contradicción entre los documentos y el repositorio que cambia el plan, un orquestador nombrado (antes de planificar hay que resolver la sección B.1 de `orchestration.md`) o una reestructuración pedida sin decir cómo debe quedar.

Nunca bloquean, porque tienen un valor por defecto: modelos, roles, lecciones, perfil de estructura, README, ubicación de las pruebas, rigor, idioma o convenciones de Git. Van en la propuesta, y la persona los cambia si quiere.

## 5. Casos que sí abren preguntas propias

Solo cuando aparecen, y con su propio procedimiento:
- **Orquestador nombrado:** el cuestionario de la sección B.1 de `orchestration.md` y su ficha (sección 15 de `templates.md`).
- **Herramienta de especificaciones o skill nombrada:** sección 1 o 2 de `tooling.md`.
- **Reestructurar:** cómo debe quedar la organización de carpetas, qué depende de las rutas (compilación, CI, importaciones) y quién más debe aprobar.
- **Varios repositorios:** sección 5 de `scenarios.md`.
- **Roles:** sección 7 de `architecture.md`, solo si la decisión 18 lo abre.

## 6. Después de la aprobación

La tabla aprobada es la **configuración acordada**. Se usa en la Fase 3 (combinación de ejes), en el plan de la Fase 4 y, si el plan se exporta, en su sección 2 (sección 16 de `templates.md`). No se vuelve a confirmar en ninguna fase posterior.
