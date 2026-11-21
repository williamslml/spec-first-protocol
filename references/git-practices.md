# Buenas prácticas de git: commits, ramas, merge, PRs y versiones

Glosario: commit = cambio guardado; merge = unir ramas; PR (pull request) = pedir revisar e integrar una rama.

Este archivo **no reinventa** las prácticas de git: las toma de dos skills publicadas, copiadas sin cambios en `references/vendor/` (origen y licencias en `vendor/README.md`), y dice cómo se aplican en SFP. Solo añade lo que ellas no traen: plantillas de mensajes legibles (sección 4), un solo formato de nombres de rama (sección 5) y reglas de seguridad para los remotes (sección 6).

| Tema | Fuente (leer la sección indicada solo cuando haga falta) |
|---|---|
| Commits atómicos (uno por cambio), mensajes que explican el porqué, separar refactor (reordenar) de lo nuevo, tamaño de los cambios | `vendor/addyosmani-agent-skills/git-workflow-and-versioning.md` → "Core Principles" secciones 2 a 5 |
| Formato Conventional Commits (tipos, asunto, cuerpo) | `vendor/0xbigboss-claude-code/git-best-practices.md` → "Conventional Commits"; ejemplos en `git-examples.md` |
| Preparar el commit: añadir archivos por nombre, revisar lo preparado, sin secretos | `git-best-practices.md` → "Commit Discipline"; `git-workflow-and-versioning.md` → "Pre-Commit Hygiene" |
| Ramas: modelo, ramas cortas, descubrir la rama por defecto (nombres: sección 5) | `git-workflow-and-versioning.md` → "Branching Strategy"; `git-best-practices.md` → "Branch Discovery", "Branch Naming", "Branch Flow" (sin `gh`, CLI de GitHub: "Branch Discovery Fallback" en `git-examples.md`) |
| Estrategia de merge (squash: juntar commits; merge commit) | `git-best-practices.md` → "Merge Strategy", resuelta en la sección 3 |
| PRs: tamaño, título, resumen, plan de pruebas; reescribir historial antes | `git-best-practices.md` → "PR Workflow" |
| Force-push (subir sobrescribiendo) y rebase (reaplicar commits) de ramas apiladas | `git-best-practices.md` → "Force Push", "Rebasing a Stack" |
| **Mensajes legibles: plantillas de commit, PR y merge** | **Este archivo, sección 4** (las fuentes no traen plantilla) |
| **Nombres de rama legibles** (un solo formato, alineado con los commits) | **Este archivo, sección 5** (une los dos formatos de las fuentes) |
| **Remotes: seguridad** (credenciales, adónde va cada push, cambios de remote) | **Este archivo, sección 6** (las fuentes no lo tratan) |
| Resumen de cambios al terminar (qué cambió, qué no se tocó, riesgos) | `git-workflow-and-versioning.md` → "Change Summaries" |
| Depurar con git (bisect, blame, log) | `git-workflow-and-versioning.md` → "Using Git for Debugging" |
| Versionado semántico, tags (etiquetas) y changelog (registro de cambios) legible | `git-workflow-and-versioning.md` → "Release & Versioning" |
| Señales de alarma y checklist por commit y por versión | `git-workflow-and-versioning.md` → "Red Flags", "Verification" |

## 1. Precedencia

1. **Política del repositorio.** Si existe, manda siempre: `CONTRIBUTING`, configuración de commitlint, plantilla de PR, reglas de protección de ramas y el estilo del historial (`git log --oneline -20`). Ambas fuentes lo dicen.
2. **Reglas de SFP** (sección 2). Mandan sobre las fuentes si chocan.
3. **Las fuentes**, por defecto si el repositorio no define nada.

Lo que se decida para el proyecto (convención de commits, modelo de ramas, estrategia de merge) va a la sección "Git" del punto de entrada (`templates.md` sección 3). Si el equipo se aparta de un valor por defecto, se registra en un ADR (registro de decisión).

## 2. Reglas de SFP que mandan sobre las fuentes

| Lo que dicen las fuentes | Lo que se hace en SFP |
|---|---|
| "Commit early, commit often" y el ciclo "Implement → Test → Verify → **Commit**" (addyosmani); commits de checkpoint `wip:` por iniciativa del agente (0xbigboss) | El agente **no hace commits por su cuenta**: sigue lo acordado (entrevista 25: commit por bloque, un solo commit o ninguno). Donde las fuentes dicen "commit", el agente **propone** el commit con su mensaje y espera. El objetivo sigue siendo commits pequeños y atómicos |
| `git reset --hard HEAD` para volver al último estado bueno (addyosmani, "The Save Point Pattern") | Destructivo (borra trabajo): solo con aprobación explícita. Antes, alternativas que no lo pierden: `git stash`, `git restore <ruta>` limitado a lo propio, o una rama de respaldo |
| "Working with Worktrees" para agentes en paralelo (addyosmani) | Lo decide la orquestación de SFP (`orchestration.md` secciones A y B): sesiones, ramas y worktrees (copias de trabajo) por sesión. No se crean fuera de ese acuerdo |
| `npm test`, `npm run lint`, `npx tsc` en la higiene previa (addyosmani) | Los comandos **reales** del proyecto: sección "Verificación" del punto de entrada y `gates.yml` (`templates.md` sección 14) |
| Automatizar con husky + lint-staged (addyosmani) | Instalar hooks (scripts automáticos de git) o dependencias cambia la configuración: ítem del plan, con aprobación (regla inviolable 7) |
| Force-push "tras confirmar con el usuario" (0xbigboss) | Igual, y además push (subir al servidor), merge, rebase de ramas compartidas, borrar ramas y crear o subir tags son **acciones de alto impacto**: aprobación humana una por una |
| `/rewrite-history` y la skill `git-rebase-sync` (0xbigboss) | No incluidas. Se siguen a mano los 6 pasos de "History Rewriting Before PR": primero rama de respaldo; aprobación antes de reescribir y antes del force-push |
| `gh repo view …` para descubrir ramas (0xbigboss) | Solo GitHub. Sin `gh`, o en GitLab u otro servidor, usar "Branch Discovery Fallback" de `git-examples.md` (`git symbolic-ref refs/remotes/origin/HEAD`) |
| "Every commit uses `type(scope): description`" (0xbigboss) | Solo si el repositorio no usa otra convención (sección 1, punto 1). Asunto en el idioma del historial |
| "Body is optional — only add one when the change is genuinely non-obvious" (0xbigboss) | En un cambio **no trivial** el cuerpo es obligatorio y sigue la plantilla de la sección 4. En un cambio trivial basta un asunto bien escrito |
| Mensajes de commit y descripciones de PR en general | Según la sección 4 (legibles para quien no conoce el código) y en español neutro si el idioma es español (regla inviolable 10). Si el proyecto eligió quitar la atribución de IA (`templates.md` sección 17), no se añaden firmas de agentes |

## 3. Contradicción resuelta: squash

addyosmani dice que el squash "destruye la narrativa del desarrollo". 0xbigboss propone squash merge por defecto de una rama de trabajo a la rama por defecto. No se contradicen si se separan dos momentos:

- **Dentro de la rama:** commits atómicos y con sentido (addyosmani). Si hubo commits `wip:` (trabajo a medias), se reescriben antes de la PR para contar una historia limpia (0xbigboss).
- **Al integrar:** manda la política del repositorio. Si no la hay, la tabla "Merge Strategy" de 0xbigboss: squash cuando la PR es **una** unidad lógica; merge commit o rebase-merge cuando sus commits son pasos con valor propio que conviene conservar (addyosmani); merge commit de la rama por defecto a producción.

## 4. Mensajes legibles: commit, PR y merge

Las fuentes piden "explicar el porqué", sin plantilla que lo asegure, y suele salir un asunto técnico que solo entiende su autor. Objetivo: que **cualquier persona del equipo** entienda qué cambió, por qué y cómo comprobarlo sin abrir el diff (líneas cambiadas). Si el repositorio tiene plantilla de PR o de commit, manda la suya (sección 1) y estas reglas se aplican dentro.

### Reglas

1. **El asunto se entiende como frase y dice el efecto, no la implementación.** En imperativo o infinitivo, según el historial, sin punto final y con menos de ~72 caracteres. Con Conventional Commits, se mantiene el prefijo `tipo(ámbito):`.
   - Mal: `feat(registro): validar formato antes de guardar` (cuenta cómo).
   - Bien: `feat(registro): rechazar emails con formato inválido al registrarse` (cuenta qué notará alguien).
2. **El cuerpo empieza por el problema**: qué pasaba antes y a quién afectaba. Es la parte que más se pierde con el tiempo.
3. **"Qué cambia" se describe desde quien usa el sistema** (persona, cliente de la API, otro equipo), no desde los archivos. Los nombres de archivo solo van si ayudan a revisar.
4. **Se dice lo que NO cambia** cuando alguien podría suponerlo (datos existentes, otras pantallas, compatibilidad).
5. **"Cómo probarlo"**: pasos concretos o el comando real del proyecto.
6. **Referencias, solo si alguien las va a usar.** Incluir el ticket (`#142`) solo si el equipo de verdad usa ese gestor de tareas y la referencia aporta contexto útil. Nunca sustituye a la explicación: el mensaje se entiende sin abrirla. No citar archivos internos, secciones, hashes (identificadores de commit) ni el CHANGELOG.
7. **Lenguaje claro, no técnico** (regla inviolable 11 de `SKILL.md`): palabras comunes, jerga explicada o evitada, siglas explicadas, sin "varios arreglos", "update", "misc", relleno ni emojis. Frases cortas, listas si hay más de una idea. Prueba: ¿lo entiende alguien del equipo que no es desarrollador?
8. **Cambio trivial** (errata, renombre, formato): basta el asunto, si se entiende solo.

### Plantilla de commit (cambio no trivial)

```text
<tipo>(<ámbito>): <efecto, entendible sin ver el código>

<Problema: qué pasaba antes y a quién afectaba. 1-3 líneas.>

Qué cambia:
- <efecto visible 1>
- <efecto visible 2>
<Qué no cambia (si alguien podría suponerlo): …>

Cómo probarlo:
- <comando real o pasos>
<Ticket, solo si el equipo lo sigue: #142>
```

Ejemplo:

```text
feat(registro): rechazar emails con formato inválido al registrarse

Hasta ahora el registro aceptaba cualquier texto como email
("ana@", "ana.com"), y esas personas nunca recibían el correo
de confirmación.

Qué cambia:
- El formulario de registro rechaza un email mal formado y
  muestra: "El email no tiene un formato válido".
- Las cuentas ya existentes no se ven afectadas.

Cómo probarlo:
- Registrarse con "ana@": aparece el mensaje de error.
- npm test
```

### Plantilla de descripción de PR

Título: el asunto del commit principal (o un resumen si hay varios), con menos de ~70 caracteres.

```markdown
## Por qué
<El problema y a quién afecta, explicado sin jerga. Enlace al ticket solo si el equipo lo usa.>

## Qué cambia
- <efecto visible, en lenguaje de quien usa el sistema>

## Qué NO cambia
- <lo que alguien podría suponer que sí cambia>

## Cómo probarlo
1. <comando real del proyecto>
2. <pasos manuales, con el resultado esperado>

## Riesgos
<Bajo/medio/alto y por qué. Qué vigilar después del merge.>
```

### Commit de merge

No dejar el texto por defecto (`Merge branch 'feat/…'`): no aporta nada al historial de la rama principal. Asunto: qué se integra y su referencia. Cuerpo: los efectos principales, uno por línea.

```text
Integra la validación de email en el registro (#142)

- Rechaza emails con formato inválido al registrarse.
- Extrae la validación a un módulo compartido.
```

Con squash merge, el mensaje del commit resultante sigue la plantilla de commit, no la lista automática que propone la plataforma.

### Revisión antes de proponer el mensaje

- ¿Alguien que no vio el código entiende el asunto?
- ¿El cuerpo dice por qué, y no solo qué?
- ¿Está escrito en el idioma acordado y, si es español, en español neutro?
- ¿Hay alguna sigla, término técnico o nombre interno sin explicar?
- ¿Hay referencias (archivos, hashes, "ver X") que nadie va a seguir? Quitarlas y explicar lo que dicen.

## 5. Ramas legibles

Las fuentes proponen dos formatos (`feature/…` y `feat/…-TICKET`). SFP usa uno solo, alineado con los commits. Si el repositorio tiene convención propia, manda esa (sección 1).

**Formato:** `<tipo>/<efecto-en-pocas-palabras>[-<ticket>]`

1. **El tipo es el mismo prefijo que los commits:** `feat/`, `fix/`, `refactor/`, `docs/`, `test/`, `chore/`, `hotfix/`. Así la rama y sus commits se leen igual.
2. **La descripción dice el efecto**, no la tarea técnica ni la persona: qué notará alguien cuando esté hecha. De 2 a 5 palabras.
3. **Solo minúsculas, números y guiones**, sin espacios, tildes, ñ ni símbolos (algunas herramientas fallan). El idioma sigue al del repositorio.
4. **El número de ticket va al final, solo si el equipo de verdad lo usa.**
5. **Nada de nombres de personas, fechas ni palabras vacías** (`test`, `tmp`, `final`, `nuevo`, `cambios`, `wip`).
6. **Menos de ~50 caracteres** en total.

| Mal | Bien | Por qué |
|---|---|---|
| `feature/validacion` | `feat/rechazar-emails-invalidos` | Dice qué cambia, no solo el tema |
| `rama-ana-2` | `fix/registro-duplicado` | Sin nombres ni números sin sentido |
| `feat/Arreglos_Varios` | `fix/totales-mal-redondeados` | Minúsculas, guiones y un solo cambio |
| `fix/se-corrige-el-error-que-aparecia-al-guardar-el-formulario` | `fix/error-al-guardar-formulario` | Corto |
| `feat/validación-email` | `feat/validar-email` | Sin tildes |

El agente propone el nombre de la rama y solo la crea con aprobación. Las ramas se borran después del merge, también con aprobación.

## 6. Remotes: tres reglas de seguridad

Un remote es la dirección del repositorio en el servidor (GitHub, GitLab…) adonde se sube el código. Solo tres reglas, porque un error aquí expone credenciales o publica código donde no debe:

1. **Nunca una contraseña o un token dentro de la dirección del remote** (`https://usuario:token@servidor/…`): queda en texto plano y sale en cualquier `git remote -v`. Para autenticarse: el gestor de credenciales del sistema o SSH. Si el análisis inicial avisa `remoto_con_credenciales`, se informa a la persona **sin mostrar el valor** y se propone corregirlo; el token se da por expuesto y se cambia.
2. **Antes de cada push se dice adónde va y qué va:** el remote y su dirección (sin credenciales), la rama de destino y los commits que se suben. Se pide aprobación con esos datos a la vista.
3. **Agregar, cambiar o borrar un remote, o cambiar la rama que sigue cada rama local, requiere aprobación**: cambia adónde se publica el código.

## 7. Relación con otras piezas de SFP

- **Specs** (especificaciones): en un cambio no trivial, cada ítem de `tasks.md` es un buen límite de commit; la PR puede enlazar la spec del cambio.
- **Revisión:** el contenido de la revisión es del rol Reviewer (`templates.md` sección 7). Este archivo solo define el formato de la PR.
- **`finishing-a-development-branch`** (si está instalada; sección 6.1 de `architecture.md`): presenta las opciones para integrar la rama. Este archivo define cómo se ejecuta la opción elegida; merge y push siguen necesitando aprobación.
- **CHANGELOG y versiones:** "Release & Versioning" de addyosmani es coherente con SFP: entrada de changelog en el mismo cambio y tag como fuente de verdad. Publicar el tag es de alto impacto.

## 8. Actualizar las fuentes

Las copias de `vendor/` están fijadas a un commit (`vendor/README.md`). Para actualizarlas: comparar con la nueva versión, copiar sin cambios, revisar si cambió alguna fila de las secciones 2 o 3 y registrarlo en el CHANGELOG de la skill.
