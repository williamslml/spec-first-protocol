# Índice de SFP por pregunta

Los textos completos (`sfp-con-orquestador.md`, `sfp-sin-orquestador.md`) tienen ~700 líneas cada uno: no se leen enteros. Primero `methodology-digest.md` (resumen); si falta detalle, buscar aquí la pregunta y leer **solo esa sección**:

```
sh <skill>/scripts/sfp-section.sh <con|sin> <número>        # p. ej.: sh scripts/sfp-section.sh sin 9.4
powershell -File <skill>\scripts\run.ps1 sfp-section sin 9.4   # Windows sin sh en el PATH
```

Sin terminal: abrir el archivo y leer desde el encabezado `## N.` (o `### N.M`) hasta el siguiente del mismo nivel. Una sección incluye sus subsecciones. `—` = no existe en esa variante.

| Pregunta | Con orquestador | Sin orquestador |
|---|---|---|
| ¿Qué es SFP, para qué y con qué alcance? | con 1 | sin 1 |
| ¿Cómo se separan las capas y por qué se nombran por función? | con 2 | sin 2 |
| ¿Cómo es el flujo general (diagrama) y qué hace un cambio trivial? | con 3 | sin 3 |
| ¿Qué responsabilidad tiene cada componente? | con 4 | sin 4 |
| ¿Quién tiene autoridad sobre qué (humano, Git, ADR, metodología)? | con 5 | sin 5 |
| ¿Cómo funciona la orquestación (supervisor, trabajadores, aislamiento)? | con 6 | — |
| ¿Cuándo se necesita una spec (especificación) y qué partes tiene un cambio? | con 7 | sin 6 |
| ¿Qué va en la spec y qué en un ADR (decisión registrada)? | con 7.1 | sin 6.1 |
| ¿En qué se diferencian runtime (entorno de ejecución), modelo y agente? | con 8 | sin 7 |
| ¿Qué agentes/roles hay y cómo se definen? | con 9 | sin 8 |
| ¿Qué niveles (tiers) de modelo hay? | con 10.1 | sin 9.1 |
| ¿Qué hace cada nivel? | con 10.2 | sin 9.2 |
| ¿Cómo se elige el modelo para una tarea? | con 10.3 | sin 9.3 |
| ¿Cuándo se sube a un nivel superior? | con 10.4 | sin 9.4 |
| ¿Cómo se hace la revisión crítica (otra sesión/modelo)? | con 10.5 | sin 9.5 |
| ¿Cuál es el ciclo de una feature importante? | con 10.6 | sin 9.6 |
| ¿Cuál es el ciclo de vida del desarrollo? | con 11 | sin 10 |
| ¿Qué controles de calidad (gates) hay y en qué orden? | con 12 | sin 11 |
| ¿Qué requiere aprobación humana y cómo se aplican permisos? | con 13 | sin 12 |
| ¿Cómo se gestiona el contexto (contexto mínimo)? | con 14 | sin 13 |
| ¿Qué contexto manda sobre cuál (jerarquía)? | con 15 | sin 14 |
| ¿Qué vive en el chat, en el proyecto y en la metodología global? | con 16 | sin 15 |
| ¿Cómo se usan Git y los ADRs? | con 17 | sin 16 |
| ¿Cómo una experiencia se vuelve lección? | con 18.1 | sin 17.1 |
| ¿Cómo se promueve una lección a la metodología global? | con 18.2 | sin 17.2 |
| ¿Qué criterios debe cumplir para promoverse? | con 18.3 | sin 17.3 |
| ¿Cómo se registran las lecciones en la práctica? | con 18.4 | sin 17.4 |
| ¿Cómo se cambia la propia metodología? | con 19 | sin 18 |
| ¿Cómo se evita que la metodología crezca sin control? | con 20 | sin 19 |
| ¿Qué estructura tiene la carpeta global? | con 21 | sin 20 |
| ¿Qué cubre cada documento de metodología? | con 21.1 | sin 20.1 |
| ¿Cómo llega la metodología a cada runtime (capa de enlace)? | con 21.2 | sin 20.2 |
| ¿Qué es un skill y cómo se organiza? | con 22 | sin 21 |
| ¿Qué papel tiene el Project Setup Skill? | con 22.1 | sin 21.1 |
| ¿Qué métricas se registran? | con 23 | sin 22 |
| ¿Cuáles son los principios fundamentales? | con 24 | sin 23 |
| ¿Cuál es la definición final y el glosario de capas? | con 25 | sin 24 |

Si una pregunta no está aquí: `grep -n "^##" references/sfp-<variante>.md` da la lista de encabezados (unas 40 líneas); luego, `sfp-section.sh` con el número.
